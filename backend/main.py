import json
import threading
import datetime
import hashlib
import hmac
import base64
import os
import secrets
import time
from typing import List, Optional
from fastapi.responses import HTMLResponse
from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import mysql.connector
from mysql.connector import pooling
import paho.mqtt.client as mqtt

TAGS_METADATA = [
    {"name": "Sistem", "description": "Status layanan 4-Node"},
    {"name": "Autentikasi", "description": "Login, registrasi, profil, dan password"},
    {"name": "Telemetri", "description": "Monitoring cold storage dan histori sensor"},
    {"name": "Staf", "description": "Manajemen hak akses role operator & staf"},
]

app = FastAPI(
    title="Smart Pharma Cloud API",
    description="Backend REST API & Admin Panel Smart Pharmaceutical & Vaccine Cold Storage.<br><br>👉 <a href=\"/dashboard\" style=\"font-weight:bold;color:#0d9488;\">Buka Admin Panel & Live Dashboard &raquo;</a>",
    docs_url="/docs",
    version="2.3.0",
    openapi_tags=TAGS_METADATA,
    swagger_ui_parameters={"docExpansion": "list", "filter": True},
)

# Enable CORS for Flutter Web and mobile apps
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
MQTT_HOST = os.getenv("MQTT_HOST", "192.168.33.10")

DB_CONFIG = {
    "host": DB_HOST,
    "port": 3306,
    "user": "root",
    "password": "fabian100607",
    "database": "pbl_db",
    "pool_name": "mypool",
    "pool_size": 5
}

try:
    db_pool = pooling.MySQLConnectionPool(**DB_CONFIG)
except Exception as e:
    print(f"[DB WARNING] Pool creation error: {e}")
    db_pool = None

def get_db():
    if db_pool:
        return db_pool.get_connection()
    return mysql.connector.connect(
        host=DB_HOST,
        port=3306,
        user="root",
        password="fabian100607",
        database="pbl_db"
    )

# ---------- Auth ----------
LEGACY_SALT = "pbl_pharma_secret_salt_2026"
PBKDF2_ITERS = 200_000
TOKEN_TTL = 7 * 24 * 3600
_KEY_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".secret_key")


def _load_secret() -> bytes:
    env = os.environ.get("PHARMA_SECRET_KEY")
    if env:
        return env.encode("utf-8")
    if os.path.exists(_KEY_PATH):
        with open(_KEY_PATH, "rb") as f:
            return f.read().strip()
    key = secrets.token_hex(32).encode("utf-8")
    fd = os.open(_KEY_PATH, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as f:
        f.write(key)
    return key


SECRET_KEY = _load_secret()


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), PBKDF2_ITERS)
    return f"pbkdf2${PBKDF2_ITERS}${salt}${dk.hex()}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    if hashed_password.startswith("pbkdf2$"):
        try:
            _, iters, salt, digest = hashed_password.split("$")
            dk = hashlib.pbkdf2_hmac("sha256", plain_password.encode("utf-8"), salt.encode("utf-8"), int(iters))
            return hmac.compare_digest(dk.hex(), digest)
        except Exception:
            return False
    legacy = hashlib.sha256((plain_password + LEGACY_SALT).encode("utf-8")).hexdigest()
    return hmac.compare_digest(legacy, hashed_password)


def needs_rehash(hashed_password: str) -> bool:
    return not hashed_password.startswith("pbkdf2$")


def _b64(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode("ascii")


def _unb64(s: str) -> bytes:
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


def create_token(user: dict) -> str:
    payload = {
        "uid": user["id"],
        "usr": user["username"],
        "role": user["role"],
        "exp": int(time.time()) + TOKEN_TTL,
    }
    body = _b64(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    sig = _b64(hmac.new(SECRET_KEY, body.encode("ascii"), hashlib.sha256).digest())
    return f"{body}.{sig}"


def decode_token(token: str) -> dict:
    try:
        body, sig = token.split(".")
        expected = _b64(hmac.new(SECRET_KEY, body.encode("ascii"), hashlib.sha256).digest())
        if not hmac.compare_digest(sig, expected):
            raise ValueError("bad signature")
        payload = json.loads(_unb64(body))
        if payload.get("exp", 0) < time.time():
            raise ValueError("expired")
        return payload
    except Exception:
        raise HTTPException(status_code=401, detail="Token tidak valid atau kedaluwarsa")


_bearer = HTTPBearer(auto_error=False)


def optional_user(cred: Optional[HTTPAuthorizationCredentials] = Depends(_bearer)) -> Optional[dict]:
    if cred and cred.scheme.lower() == "bearer":
        try:
            return decode_token(cred.credentials)
        except Exception:
            pass
    return None


def require_user(cred: HTTPAuthorizationCredentials = Depends(_bearer)) -> dict:
    if cred is None or cred.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="Autentikasi diperlukan")
    return decode_token(cred.credentials)


def require_operator(user: dict = Depends(require_user)) -> dict:
    """Verifikasi hak akses Operator langsung ke DB"""
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT role FROM users WHERE id = %s", (user["uid"],))
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        current_role = row["role"] if row else user.get("role")
    except Exception:
        current_role = user.get("role")

    if current_role not in ["operator", "admin"]:
        raise HTTPException(status_code=403, detail="Akses ditolak: hanya operator yang memiliki izin")
    user["role"] = current_role
    return user


_FAILS: dict = {}
MAX_FAILS = 5
LOCK_SECONDS = 300


def _fail_key(request: Request, username: str) -> str:
    ip = request.client.host if request.client else "?"
    return f"{ip}|{username.strip().lower()}"


def check_lock(key: str):
    rec = _FAILS.get(key)
    if rec and rec[0] >= MAX_FAILS:
        if time.time() < rec[1]:
            raise HTTPException(status_code=429, detail="Terlalu banyak percobaan. Coba lagi beberapa menit.")
        _FAILS.pop(key, None)


def record_fail(key: str):
    cnt = _FAILS.get(key, (0, 0))[0] + 1
    _FAILS[key] = (cnt, time.time() + LOCK_SECONDS)


def init_db():
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS sensor_data (
                id INT AUTO_INCREMENT PRIMARY KEY,
                device_id VARCHAR(50) DEFAULT 'device_1',
                suhu FLOAT NOT NULL,
                kelembapan FLOAT NOT NULL,
                kadar_gas FLOAT DEFAULT 0.0,
                cahaya FLOAT DEFAULT 0.0,
                status_pintu INT DEFAULT 0,
                status_uv INT DEFAULT 0,
                status VARCHAR(50) DEFAULT 'Aman',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                full_name VARCHAR(100) NOT NULL,
                email VARCHAR(100) NOT NULL,
                role VARCHAR(30) DEFAULT 'user',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        cursor.close()
        conn.close()
        print("[INIT DB] Database & Users schema verified")
    except Exception as e:
        print(f"[INIT DB ERROR] {e}")

init_db()

# ---------- Pydantic Request Models ----------
class LoginRequest(BaseModel):
    username: str
    password: str

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str

class UpdateProfileRequest(BaseModel):
    full_name: str
    email: str

class RegisterRequest(BaseModel):
    username: str
    password: str
    full_name: str
    email: str
    role: str = "user"

class CreateUserRequest(BaseModel):
    username: str
    password: str
    full_name: str
    email: str
    role: str = "user"

class UpdateUserRequest(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    role: Optional[str] = None

class AdminResetPasswordRequest(BaseModel):
    new_password: str

class UpdateUserRoleRequest(BaseModel):
    user_id: int
    role: str

class ActuatorControlRequest(BaseModel):
    state: int
    device_id: str = "device_2"

# ---------- Pydantic Response Models ----------
class UserProfile(BaseModel):
    id: int
    username: str
    name: str
    email: str
    role: str

class AuthResponse(BaseModel):
    success: bool
    message: str
    token: str
    user: UserProfile

class StatusResponse(BaseModel):
    app: str
    status: str
    architecture: str

class SensorItem(BaseModel):
    id: Optional[int] = None
    device_id: str
    suhu: float
    kelembapan: float
    kadar_gas: float
    cahaya: Optional[float] = 0.0
    status_pintu: int
    status_uv: int
    status: str
    created_at: Optional[str] = None
    waktu: Optional[str] = None

class SensorSummary(BaseModel):
    total_records: int
    avg_suhu: Optional[float] = None
    min_suhu: Optional[float] = None
    max_suhu: Optional[float] = None
    avg_kelembapan: Optional[float] = None
    avg_gas: Optional[float] = None
    avg_cahaya: Optional[float] = None

class GenericResponse(BaseModel):
    success: bool
    message: str


def process_and_save_sensor_data(data: dict):
    """Pengolahan Data Cloud: Analisis batas aman cold-chain vaksin & gas berbahaya"""
    device_id = str(data.get("device_id", data.get("deviceId", "device_1")))
    suhu = float(data.get("suhu", 0.0))
    kelembapan = float(data.get("kelembapan", 0.0))
    kadar_gas = float(data.get("kadar_gas", data.get("gas", 0.0)))
    cahaya = float(data.get("cahaya", data.get("lux", 0.0)))
    status_pintu = int(data.get("status_pintu", 0))
    status_uv = int(data.get("status_uv", 0))

    if kadar_gas > 50 or status_pintu == 1 or cahaya > 600:
        status = "Bahaya"
    elif suhu < 2.0 or suhu > 8.0 or cahaya > 300:
        status = "Peringatan"
    else:
        status = "Aman"

    try:
        conn = get_db()
        cursor = conn.cursor()
        query = """
            INSERT INTO sensor_data (device_id, suhu, kelembapan, kadar_gas, cahaya, status_pintu, status_uv, status, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW())
        """
        cursor.execute(query, (device_id, suhu, kelembapan, kadar_gas, cahaya, status_pintu, status_uv, status))
        conn.commit()
        cursor.close()
        conn.close()
        print(f"[DATA SAVED] {device_id} | Suhu: {suhu}°C | Cahaya: {cahaya} Lux | Status: {status}")
    except Exception as e:
        print(f"[SAVE ERROR] {e}")

mqtt_client_global = None

def on_mqtt_connect(client, userdata, flags, rc, properties=None):
    global mqtt_client_global
    mqtt_client_global = client
    print(f"[MQTT] Terhubung ke broker Mosquitto (rc={rc})")
    client.subscribe("pharma/sensor")
    client.subscribe("greenhouse/sensor")
    client.subscribe("pharma/+/sensor")

def on_mqtt_message(client, userdata, msg):
    try:
        payload = msg.payload.decode("utf-8")
        data = json.loads(payload)
        process_and_save_sensor_data(data)
    except Exception as e:
        print(f"[MQTT PARSE ERROR] {e}")

def publish_mqtt(topic: str, message: str) -> bool:
    global mqtt_client_global
    if mqtt_client_global:
        try:
            mqtt_client_global.publish(topic, message)
            print(f"[MQTT PUB] {topic}: {message}")
            return True
        except Exception as e:
            print(f"[MQTT PUB ERROR] {e}")
    return False

def start_mqtt_listener():
    candidates = ["172.17.0.1", MQTT_HOST, "172.17.0.2", "192.168.33.10", "127.0.0.1"]
    for host in candidates:
        try:
            client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
            client.on_connect = on_mqtt_connect
            client.on_message = on_mqtt_message
            client.connect(host, 1883, 60)
            print(f"[MQTT] Connected to broker at {host}:1883")
            client.loop_forever()
            return
        except Exception:
            pass
    print("[MQTT THREAD ERROR] Could not connect to any broker candidates")

mqtt_thread = threading.Thread(target=start_mqtt_listener, daemon=True)
mqtt_thread.start()


# ---------- Endpoints ----------

@app.get("/admin", include_in_schema=False)
@app.get("/dashboard", include_in_schema=False)
def get_dashboard():
    dashboard_path = os.path.join(os.path.dirname(__file__), "dashboard.html")
    with open(dashboard_path, "r", encoding="utf-8") as f:
        return HTMLResponse(content=f.read())

@app.get("/", tags=["Sistem"], response_model=StatusResponse, summary="Cek Status Layanan")
def root():
    return {
        "app": "Pharma Medic IoT Cloud Service",
        "status": "Online",
        "architecture": "4-Node Microservices (Backend, DB, MQTT, Auto-Backup)"
    }

@app.post("/login", tags=["Autentikasi"], response_model=AuthResponse, summary="Login Akun")
def login_user(req: LoginRequest, request: Request):
    """Autentikasi User Farmasi via Database MySQL Node 2"""
    fkey = _fail_key(request, req.username)
    check_lock(fkey)
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "SELECT id, username, password_hash, full_name, email, role FROM users WHERE username = %s",
            (req.username.strip(),)
        )
        user = cursor.fetchone()

        if not user or not verify_password(req.password, user["password_hash"]):
            cursor.close()
            conn.close()
            record_fail(fkey)
            raise HTTPException(status_code=401, detail="Username atau password salah")

        if needs_rehash(user["password_hash"]):
            cursor.execute("UPDATE users SET password_hash = %s WHERE id = %s", (hash_password(req.password), user["id"]))
            conn.commit()
        cursor.close()
        conn.close()
        _FAILS.pop(fkey, None)

        return {
            "success": True,
            "message": "Login berhasil",
            "token": create_token(user),
            "user": {
                "id": user["id"],
                "username": user["username"],
                "name": user["full_name"],
                "email": user["email"],
                "role": user["role"]
            }
        }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Database error")

@app.post("/register", tags=["Autentikasi"], response_model=AuthResponse, summary="Registrasi Akun")
def register_user(req: RegisterRequest):
    """Pendaftaran Akun Baru Petugas/User (Otomatis role: user)"""
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id FROM users WHERE username = %s", (req.username.strip(),))
        existing = cursor.fetchone()
        if existing:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="Username sudah digunakan")

        if len(req.password) < 8:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="Password minimal 8 karakter")

        role = "user"
        pwd_hash = hash_password(req.password)
        cursor.execute("""
            INSERT INTO users (username, password_hash, full_name, email, role)
            VALUES (%s, %s, %s, %s, %s)
        """, (req.username.strip(), pwd_hash, req.full_name.strip(), req.email.strip(), role))
        conn.commit()
        new_id = cursor.lastrowid
        cursor.close()
        conn.close()

        return {
            "success": True,
            "message": "Registrasi berhasil",
            "token": create_token({"id": new_id, "username": req.username.strip(), "role": role}),
            "user": {
                "id": new_id,
                "username": req.username.strip(),
                "name": req.full_name.strip(),
                "email": req.email.strip(),
                "role": role
            }
        }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Database error")

@app.get("/me", tags=["Autentikasi"], summary="Profil Pengguna Aktif")
def get_me(user: dict = Depends(require_user)):
    """Ambil data profil dan role pengguna aktif terbaru dari DB"""
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, username, full_name, email, role, created_at FROM users WHERE id = %s", (user["uid"],))
        db_user = cursor.fetchone()
        cursor.close()
        conn.close()
        if not db_user:
            raise HTTPException(status_code=404, detail="User tidak ditemukan")
        if isinstance(db_user.get("created_at"), (datetime.date, datetime.datetime)):
            db_user["created_at"] = db_user["created_at"].strftime("%Y-%m-%d %H:%M:%S")
        return {
            "id": db_user["id"],
            "username": db_user["username"],
            "name": db_user["full_name"],
            "email": db_user["email"],
            "role": db_user["role"],
            "created_at": db_user["created_at"]
        }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Database error")

@app.get("/users", tags=["Staf"], summary="Daftar Staf")
def get_users(_user: dict = Depends(require_operator)):
    """List semua user untuk manajemen role oleh operator"""
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, username, full_name, email, role, created_at FROM users ORDER BY id ASC")
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        for r in rows:
            if isinstance(r.get("created_at"), (datetime.date, datetime.datetime)):
                r["created_at"] = r["created_at"].strftime("%Y-%m-%d %H:%M:%S")
        return rows
    except Exception:
        raise HTTPException(status_code=500, detail="Database error")

@app.post("/admin/users", tags=["Staf"], summary="Tambah Akun Staf (Operator)")
def admin_create_user(req: CreateUserRequest, _op: dict = Depends(require_operator)):
    """Operator menambah akun baru dengan role pilihan (operator atau user)"""
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id FROM users WHERE username = %s", (req.username.strip(),))
        existing = cursor.fetchone()
        if existing:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="Username sudah digunakan")

        if len(req.password) < 6:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="Password minimal 6 karakter")

        role = req.role.strip().lower()
        if role not in ["user", "operator"]:
            role = "user"

        pwd_hash = hash_password(req.password)
        cursor.execute("""
            INSERT INTO users (username, password_hash, full_name, email, role)
            VALUES (%s, %s, %s, %s, %s)
        """, (req.username.strip(), pwd_hash, req.full_name.strip(), req.email.strip(), role))
        conn.commit()
        new_id = cursor.lastrowid
        cursor.close()
        conn.close()

        return {
            "success": True,
            "message": f"Staf '{req.username.strip()}' berhasil ditambahkan sebagai '{role}'",
            "user": {
                "id": new_id,
                "username": req.username.strip(),
                "full_name": req.full_name.strip(),
                "email": req.email.strip(),
                "role": role
            }
        }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Database error")

@app.post("/users/{user_id}/update", tags=["Staf"], summary="Edit Data Staf (Operator)")
def admin_update_user(user_id: int, req: UpdateUserRequest, operator: dict = Depends(require_operator)):
    """Operator mengedit nama, email, atau role staf"""
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, username, full_name, email, role FROM users WHERE id = %s", (user_id,))
        target = cursor.fetchone()
        if not target:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail="User tidak ditemukan")

        new_name = req.full_name.strip() if req.full_name is not None and req.full_name.strip() else target["full_name"]
        new_email = req.email.strip() if req.email is not None and req.email.strip() else target["email"]
        new_role = req.role.strip().lower() if req.role is not None and req.role.strip() else target["role"]

        if new_role not in ["operator", "user"]:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="Role tidak valid (hanya operator atau user)")

        if user_id == operator["uid"] and new_role != "operator":
            cursor.close()
            conn.close()
            raise HTTPException(status_code=400, detail="Tidak dapat mencabut hak operator akun sendiri")

        cursor.execute(
            "UPDATE users SET full_name = %s, email = %s, role = %s WHERE id = %s",
            (new_name, new_email, new_role, user_id)
        )
        conn.commit()
        cursor.close()
        conn.close()
        return {
            "success": True,
            "message": f"Data staf '{target['username']}' berhasil diperbarui"
        }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Database error")

@app.post("/users/{user_id}/reset-password", tags=["Staf"], summary="Reset Password Staf (Operator)")
def admin_reset_password(user_id: int, req: AdminResetPasswordRequest, _op: dict = Depends(require_operator)):
    """Operator mereset password pengguna lain"""
    if len(req.new_password) < 6:
        raise HTTPException(status_code=400, detail="Password baru minimal 6 karakter")
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, username FROM users WHERE id = %s", (user_id,))
        target = cursor.fetchone()
        if not target:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail="User tidak ditemukan")

        new_hash = hash_password(req.new_password)
        cursor.execute("UPDATE users SET password_hash = %s WHERE id = %s", (new_hash, user_id))
        conn.commit()
        cursor.close()
        conn.close()
        return {
            "success": True,
            "message": f"Password untuk '{target['username']}' berhasil direset"
        }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Database error")

@app.post("/users/role", tags=["Staf"], summary="Ubah Role Staf")
def update_user_role(req: UpdateUserRoleRequest, user: dict = Depends(require_operator)):
    """Operator mengubah role pengguna lain (user <-> operator)"""
    target_role = req.role.strip().lower()
    if target_role not in ["operator", "user"]:
        raise HTTPException(status_code=400, detail="Role tidak valid (hanya operator atau user)")

    if req.user_id == user["uid"] and target_role != "operator":
        raise HTTPException(status_code=400, detail="Tidak dapat mencabut hak operator akun sendiri")

    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, username, role FROM users WHERE id = %s", (req.user_id,))
        target = cursor.fetchone()
        if not target:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail="User tidak ditemukan")

        cursor.execute("UPDATE users SET role = %s WHERE id = %s", (target_role, req.user_id))
        conn.commit()
        cursor.close()
        conn.close()
        return {
            "success": True,
            "message": f"Role '{target['username']}' berhasil diubah menjadi '{target_role}'",
            "user_id": req.user_id,
            "role": target_role
        }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Database error")

@app.delete("/users/{user_id}", tags=["Staf"], summary="Hapus Akun Staf")
def delete_user(user_id: int, user: dict = Depends(require_operator)):
    """Operator menghapus akun user"""
    if user_id == user["uid"]:
        raise HTTPException(status_code=400, detail="Tidak dapat menghapus akun sendiri yang sedang aktif")

    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, username FROM users WHERE id = %s", (user_id,))
        target = cursor.fetchone()
        if not target:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail="User tidak ditemukan")

        cursor.execute("DELETE FROM users WHERE id = %s", (user_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return {
            "success": True,
            "message": f"Pengguna '{target['username']}' berhasil dihapus",
            "user_id": user_id
        }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Database error")

@app.get("/sensor", tags=["Telemetri"], response_model=List[SensorItem], summary="Riwayat Sensor")
def get_sensor_data(limit: int = 50, _user: dict = Depends(require_user)):
    """Ambil riwayat data sensor untuk mobile app dan export CSV"""
    limit = max(1, min(limit, 500))
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM sensor_data ORDER BY id DESC LIMIT %s", (limit,))
        rows = cursor.fetchall()
        cursor.close()
        conn.close()

        for r in rows:
            if isinstance(r.get("created_at"), (datetime.date, datetime.datetime)):
                r["created_at"] = r["created_at"].strftime("%Y-%m-%d %H:%M:%S")
                r["waktu"] = r["created_at"]

        if not rows:
            return [{
                "device_id": "device_1",
                "suhu": 4.5,
                "kelembapan": 45.0,
                "kadar_gas": 12.0,
                "cahaya": 120.0,
                "status_pintu": 0,
                "status_uv": 0,
                "status": "Aman",
                "created_at": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "waktu": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }]
        return rows
    except Exception as e:
        print(f"[GET SENSOR ERROR] {e}")
        return [{
            "device_id": "device_1",
            "suhu": 4.5,
            "kelembapan": 45.0,
            "kadar_gas": 12.0,
            "cahaya": 120.0,
            "status_pintu": 0,
            "status_uv": 0,
            "status": "Aman",
            "waktu": "2026-10-23 00:00:00"
        }]

@app.delete("/sensor/{sensor_id}", tags=["Telemetri"], summary="Hapus Log Sensor")
def delete_sensor_record(sensor_id: int, _op: dict = Depends(require_operator)):
    """Operator menghapus baris riwayat sensor tertentu"""
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM sensor_data WHERE id = %s", (sensor_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return {"success": True, "message": f"Log sensor #{sensor_id} berhasil dihapus"}
    except Exception:
        raise HTTPException(status_code=500, detail="Database error")

@app.get("/sensor/summary", tags=["Telemetri"], response_model=SensorSummary, summary="Ringkasan Statistik")
def get_sensor_summary(_user: dict = Depends(require_user)):
    """Pengolahan Data Agregat: Rata-rata, Min/Max, & Status Rantai Dingin"""
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT 
                COUNT(*) as total_records,
                ROUND(AVG(suhu), 2) as avg_suhu,
                ROUND(MIN(suhu), 2) as min_suhu,
                ROUND(MAX(suhu), 2) as max_suhu,
                ROUND(AVG(kelembapan), 2) as avg_kelembapan,
                ROUND(AVG(kadar_gas), 2) as avg_gas,
                ROUND(AVG(cahaya), 1) as avg_cahaya
            FROM sensor_data
        """)
        summary = cursor.fetchone()
        cursor.close()
        conn.close()
        return summary
    except Exception:
        raise HTTPException(status_code=500, detail="Server error")

# Menerima data dari tombol 'Kirim Node' di Web Dashboard.
# Alur ke Flutter:
# 1. Simpan ke database MySQL (Node 2).
# 2. Broadcast ke broker MQTT topik 'pharma/sensor' (Node 3).
# 3. Flutter yang subscribe topik ini langsung menerima data secara realtime.
@app.post("/kirim-data", tags=["Telemetri"], summary="Kirim Data Sensor")
def kirim_data(data_baru: dict, _user: Optional[dict] = Depends(optional_user)):
    process_and_save_sensor_data(data_baru)
    try:
        publish_mqtt("pharma/sensor", json.dumps(data_baru))
    except Exception:
        pass
    return {"pesan": "Data berhasil diolah dan disimpan ke Database Node 2", "data": data_baru}

@app.post("/control/{device}", tags=["Telemetri"], summary="Kontrol Aktuator IoT")
def control_actuator(device: str, req: ActuatorControlRequest, _user: dict = Depends(require_user)):
    """Kirim perintah kontrol aktuator ke MQTT Broker (uv, buzzer, fan, pump)"""
    device_name = device.lower().strip()
    topic_specific = f"pharma/control/{device_name}"
    payload_specific = json.dumps({"device_id": req.device_id, "state": req.state})
    topic_generic = f"pharma/control/{req.device_id}"
    payload_generic = json.dumps({"actuator": device_name, "state": req.state})

    pub1 = publish_mqtt(topic_specific, payload_specific)
    pub2 = publish_mqtt(topic_generic, payload_generic)

    return {
        "success": pub1 or pub2,
        "message": f"Perintah {device_name} (state={req.state}) berhasil dikirim ke Broker MQTT",
        "device": device_name,
        "state": req.state
    }

@app.post("/change-password", tags=["Autentikasi"], response_model=GenericResponse, summary="Ganti Password")
def change_password(req: ChangePasswordRequest, user: dict = Depends(require_user)):
    """Ganti Password Pengguna yang Sedang Login"""
    if len(req.new_password) < 6:
        raise HTTPException(status_code=400, detail="Password baru minimal 6 karakter")

    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT id, password_hash FROM users WHERE id = %s", (user["uid"],))
    db_user = cursor.fetchone()
    if not db_user or not verify_password(req.old_password, db_user["password_hash"]):
        cursor.close()
        conn.close()
        raise HTTPException(status_code=400, detail="Password lama tidak sesuai")

    new_hash = hash_password(req.new_password)
    cursor.execute("UPDATE users SET password_hash = %s WHERE id = %s", (new_hash, user["uid"]))
    conn.commit()
    cursor.close()
    conn.close()
    return {"success": True, "message": "Password berhasil diperbarui"}

@app.post("/update-profile", tags=["Autentikasi"], response_model=GenericResponse, summary="Perbarui Profil")
def update_profile(req: UpdateProfileRequest, user: dict = Depends(require_user)):
    """Update Nama & Email Pengguna"""
    if not req.full_name.strip() or not req.email.strip():
        raise HTTPException(status_code=400, detail="Nama dan email tidak boleh kosong")
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("UPDATE users SET full_name = %s, email = %s WHERE id = %s", (req.full_name.strip(), req.email.strip(), user["uid"]))
    conn.commit()
    cursor.close()
    conn.close()
    return {"success": True, "message": "Profil berhasil diperbarui"}
