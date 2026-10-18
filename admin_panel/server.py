import os
import json
import time
import socket
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

PORT = 8085
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(BASE_DIR, "live_database.json")

# In-memory SSE subscribers
sse_clients = []
sse_lock = threading.Lock()

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

LOCAL_IP = get_local_ip()

def load_database():
    if os.path.exists(DB_FILE):
        try:
            with open(DB_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass

    recipes = []
    recipes_path = os.path.join(r"C:\Users\Furkan\.gemini\antigravity-ide\brain\174e0c8a-77e3-4bcb-9879-db1fdd5ab1b7\scratch\lezzet_recipes.json")
    if os.path.exists(recipes_path):
        try:
            with open(recipes_path, "r", encoding="utf-8") as f:
                recipes = json.load(f)
        except Exception:
            pass

    default_db = {
        "students": [],
        "teachers": [],
        "evaluations": [],
        "recipes": recipes,
        "tasks": [],
        "lastUpdated": time.time()
    }
    save_database(default_db)
    return default_db

def save_database(data):
    data["lastUpdated"] = time.time()
    with open(DB_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def broadcast_event(event_type, payload):
    data_str = json.dumps({"type": event_type, "data": payload, "timestamp": time.time()}, ensure_ascii=False)
    msg = f"event: {event_type}\ndata: {data_str}\n\n".encode("utf-8")
    
    with sse_lock:
        to_remove = []
        for client in sse_clients:
            try:
                client.wfile.write(msg)
                client.wfile.flush()
            except Exception:
                to_remove.append(client)
        for dead in to_remove:
            if dead in sse_clients:
                sse_clients.remove(dead)

class LiveSyncHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BASE_DIR, **kwargs)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/api/stream":
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.end_headers()
            
            with sse_lock:
                sse_clients.append(self)

            init_msg = f"event: connected\ndata: {json.dumps({'status': 'live', 'ip': LOCAL_IP})}\n\n".encode("utf-8")
            try:
                self.wfile.write(init_msg)
                self.wfile.flush()
                while True:
                    time.sleep(15)
                    self.wfile.write(b": heartbeat\n\n")
                    self.wfile.flush()
            except Exception:
                pass
            finally:
                with sse_lock:
                    if self in sse_clients:
                        sse_clients.remove(self)
            return

        if path.startswith("/api/"):
            db = load_database()
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.end_headers()

            if path == "/api/status":
                resp = {
                    "status": "online",
                    "localIp": LOCAL_IP,
                    "port": PORT,
                    "connectedClients": len(sse_clients),
                    "totalStudents": len(db.get("students", [])),
                    "totalEvaluations": len(db.get("evaluations", [])),
                    "totalRecipes": len(db.get("recipes", []))
                }
                self.wfile.write(json.dumps(resp, ensure_ascii=False).encode("utf-8"))
            elif path == "/api/students":
                self.wfile.write(json.dumps(db.get("students", []), ensure_ascii=False).encode("utf-8"))
            elif path == "/api/teachers":
                self.wfile.write(json.dumps(db.get("teachers", []), ensure_ascii=False).encode("utf-8"))
            elif path == "/api/evaluations":
                self.wfile.write(json.dumps(db.get("evaluations", []), ensure_ascii=False).encode("utf-8"))
            elif path == "/api/recipes":
                self.wfile.write(json.dumps(db.get("recipes", []), ensure_ascii=False).encode("utf-8"))
            elif path == "/api/tasks":
                self.wfile.write(json.dumps(db.get("tasks", []), ensure_ascii=False).encode("utf-8"))
            else:
                self.wfile.write(json.dumps({"error": "Not found"}).encode("utf-8"))
            return

        super().do_GET()

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path

        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode("utf-8") if content_length > 0 else "{}"
        try:
            payload = json.loads(body)
        except Exception:
            payload = {}

        db = load_database()
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.end_headers()

        if path == "/api/evaluations":
            new_id = payload.get("id") or f"eval_{int(time.time()*1000)}"
            new_eval = {
                "id": new_id,
                "studentId": payload.get("studentId", "s_mobile"),
                "studentName": payload.get("studentName", "Öğrenci"),
                "studentAvatar": payload.get("studentAvatar", "🧒"),
                "formType": payload.get("formType", "okul"),
                "formTitle": payload.get("formTitle", "Gözlem Formu"),
                "date": payload.get("date") or time.strftime("%d.%m.%Y"),
                "time": payload.get("time") or time.strftime("%H:%M"),
                "status": "pending",
                "teacherNote": "",
                "mood": payload.get("mood", "İyi 😊"),
                "answers": payload.get("answers", [])
            }
            db["evaluations"].insert(0, new_eval)

            # Ogrenciyi otomatik olarak ogrenci listesine kaydet / guncelle
            s_name = new_eval["studentName"]
            existing_s = next((s for s in db.get("students", []) if s.get("name") == s_name), None)
            if existing_s:
                existing_s["lastActive"] = f"{new_eval['date']} {new_eval['time']}"
            else:
                new_s = {
                    "id": new_eval["studentId"],
                    "name": s_name,
                    "avatar": new_eval["studentAvatar"],
                    "age": 14,
                    "diagnosis": "Özel Eğitim Öğrencisi",
                    "parentName": "Veli",
                    "parentPhone": "05XX XXX XX XX",
                    "cashBudget": 500,
                    "cardLimit": 1000,
                    "cardRemaining": 1000,
                    "lastActive": f"{new_eval['date']} {new_eval['time']}",
                    "streakDays": 1
                }
                db.setdefault("students", []).append(new_s)
                broadcast_event("student_added", new_s)

            save_database(db)
            broadcast_event("new_evaluation", new_eval)
            self.wfile.write(json.dumps({"success": True, "evaluation": new_eval}, ensure_ascii=False).encode("utf-8"))

        elif path == "/api/evaluations/review":
            target_id = payload.get("id")
            note = payload.get("teacherNote", "")
            for item in db["evaluations"]:
                if item["id"] == target_id:
                    item["status"] = "reviewed"
                    item["teacherNote"] = note
                    break
            save_database(db)
            broadcast_event("evaluation_reviewed", {"id": target_id, "teacherNote": note})
            self.wfile.write(json.dumps({"success": True}, ensure_ascii=False).encode("utf-8"))

        elif path == "/api/recipes":
            rec_id = payload.get("id") or f"rec_{int(time.time()*1000)}"
            payload["id"] = rec_id
            found = False
            for i, r in enumerate(db["recipes"]):
                if r["id"] == rec_id:
                    db["recipes"][i] = payload
                    found = True
                    break
            if not found:
                db["recipes"].insert(0, payload)
            save_database(db)
            broadcast_event("recipes_updated", payload)
            self.wfile.write(json.dumps({"success": True, "recipe": payload}, ensure_ascii=False).encode("utf-8"))

        elif path == "/api/students":
            clean_name = (payload.get("name") or "").strip()
            if not clean_name:
                self.wfile.write(json.dumps({"error": "Name is required"}).encode("utf-8"))
                return
            student_id = payload.get("id") or f"std_{int(time.time()*1000)}"
            payload["id"] = student_id
            payload["name"] = clean_name
            s_name = clean_name.lower()
            existing_idx = -1
            for i, s in enumerate(db.get("students", [])):
                if s.get("id") == student_id or (s.get("name") or "").strip().lower() == s_name:
                    existing_idx = i
                    break
            
            if existing_idx >= 0:
                db["students"][existing_idx].update(payload)
                saved_student = db["students"][existing_idx]
            else:
                db.setdefault("students", []).insert(0, payload)
                saved_student = payload

            save_database(db)
            broadcast_event("student_added", saved_student)
            self.wfile.write(json.dumps({"success": True, "student": saved_student}, ensure_ascii=False).encode("utf-8"))

        elif path == "/api/students/delete":
            target_id = payload.get("id")
            db["students"] = [s for s in db.get("students", []) if s.get("id") != target_id]
            save_database(db)
            broadcast_event("student_deleted", {"id": target_id})
            self.wfile.write(json.dumps({"success": True, "id": target_id}, ensure_ascii=False).encode("utf-8"))

        elif path == "/api/reset-data":
            db["students"] = []
            db["evaluations"] = []
            save_database(db)
            broadcast_event("database_reset", {})
            self.wfile.write(json.dumps({"success": True}, ensure_ascii=False).encode("utf-8"))

        elif path == "/api/teachers":
            teacher_id = payload.get("id") or f"tch_{int(time.time()*1000)}"
            payload["id"] = teacher_id
            db["teachers"].append(payload)
            save_database(db)
            broadcast_event("teacher_added", payload)
            self.wfile.write(json.dumps({"success": True, "teacher": payload}, ensure_ascii=False).encode("utf-8"))

        elif path == "/api/tasks":
            task_id = payload.get("id") or f"tsk_{int(time.time()*1000)}"
            payload["id"] = task_id
            db["tasks"].insert(0, payload)
            save_database(db)
            broadcast_event("task_added", payload)
            self.wfile.write(json.dumps({"success": True, "task": payload}, ensure_ascii=False).encode("utf-8"))

        else:
            self.wfile.write(json.dumps({"error": "Unknown POST route"}).encode("utf-8"))

def run():
    load_database()
    server = ThreadingHTTPServer(("0.0.0.0", PORT), LiveSyncHandler)
    print(f"============================================================")
    print(f"  OZEL ADIMLAR CANLI SENKRONIZASYON SUNUCUSU BASLATILDI")
    print(f"  Tarayici Baglantisi : http://localhost:{PORT}")
    print(f"  Mobil / Ag IP       : http://{LOCAL_IP}:{PORT}")
    print(f"============================================================")
    server.serve_forever()

if __name__ == "__main__":
    run()
