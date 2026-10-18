// ============================================================
// ÖZEL APP YÖNETİM & ÖĞRETMEN PORTALI - CANLI VERİ SERVİSİ
// ============================================================
// Google Firebase Firestore (ozel-app-4ee23) üzerinden 7/24
// dünyanın her yerinden kesintisiz canlı senkronizasyon sağlar.

const firebaseConfig = {
  apiKey: "AIzaSyDCuy-5UBSWONW7X8TGr7O-hBGLfCUY9Nw",
  authDomain: "ozel-app-4ee23.firebaseapp.com",
  projectId: "ozel-app-4ee23",
  storageBucket: "ozel-app-4ee23.firebasestorage.app",
  messagingSenderId: "1038449522306",
  appId: "1:1038449522306:web:f30d07fa7167f5bb1de69b",
  measurementId: "G-FTDPXTXGHM"
};

class PanelDataService {
  constructor() {
    this.apiBase = window.location.origin;
    this.students = [];
    this.teachers = [];
    this.forms = [];
    this.recipes = [];
    this.tasks = [];
    this.activeRole = 'admin';
    this.activeTeacherId = '';
    this.isLiveConnected = false;
    this.db = null;

    this._initFirebase();
    this._initLiveStream();
    this.loadAllFromApi();
  }

  // 1. Google Firebase Firestore Canlı Bulut Bağlantısı
  _initFirebase() {
    try {
      if (typeof firebase !== 'undefined') {
        if (!firebase.apps || !firebase.apps.length) {
          firebase.initializeApp(firebaseConfig);
        }
        this.db = firebase.firestore();
        console.log('🔥 Firebase Firestore Bağlandı (ozel-app-4ee23)');
        this._updateConnectionIndicator(true, 'Firebase Bulut (ozel-app-4ee23)');

        // CANLI ÖĞRENCİ DİNLEYİCİSİ (Realtime Snapshot)
        this.db.collection('students').onSnapshot((snapshot) => {
          const list = [];
          snapshot.forEach((doc) => {
            const data = doc.data();
            data.id = doc.id;
            list.push(data);
          });
          if (list.length > 0 || snapshot.metadata.hasPendingWrites === false) {
            this.students = list;
            if (typeof renderCurrentView === 'function') renderCurrentView();
          }
        }, (err) => console.warn('Firestore students stream:', err));

        // CANLI ANKETLER / DEĞERLENDİRME FORMLARI DİNLEYİCİSİ
        this.db.collection('evaluations').onSnapshot((snapshot) => {
          const list = [];
          snapshot.forEach((doc) => {
            const data = doc.data();
            data.id = doc.id;
            list.push(data);
          });
          list.sort((a, b) => (b.id || '').localeCompare(a.id || ''));
          this.forms = list;
          if (typeof renderCurrentView === 'function') renderCurrentView();
        }, (err) => console.warn('Firestore evaluations stream:', err));

        // CANLI TARİFLER DİNLEYİCİSİ
        this.db.collection('recipes').onSnapshot((snapshot) => {
          if (!snapshot.empty) {
            const list = [];
            snapshot.forEach((doc) => {
              const data = doc.data();
              data.id = doc.id;
              list.push(data);
            });
            list.sort((a, b) => (a.number || 0) - (b.number || 0));
            this.recipes = list;
            if (typeof renderCurrentView === 'function') renderCurrentView();
          }
        }, (err) => console.warn('Firestore recipes stream:', err));

        // CANLI GÖREVLER DİNLEYİCİSİ (Realtime Tasks Snapshot)
        this.db.collection('tasks').onSnapshot((snapshot) => {
          const list = [];
          snapshot.forEach((doc) => {
            const data = doc.data();
            data.id = doc.id;
            list.push(data);
          });
          list.sort((a, b) => (b.id || '').localeCompare(a.id || ''));
          this.tasks = list;
          if (typeof renderCurrentView === 'function') renderCurrentView();
        }, (err) => console.warn('Firestore tasks stream:', err));
      }
    } catch (e) {
      console.warn('Firebase init fallback:', e);
    }
  }

  // 2. Canlı SSE (Server-Sent Events) Akışı (Yerel Sunucu Yedek Hattı)
  _initLiveStream() {
    if (typeof EventSource === 'undefined') return;

    try {
      this.eventSource = new EventSource(`${this.apiBase}/api/stream`);

      this.eventSource.addEventListener('connected', (e) => {
        if (!this.db) {
          this.isLiveConnected = true;
          const data = JSON.parse(e.data);
          console.log('⚡ Canlı Senkronizasyon Bağlandı. Ağ IP:', data.ip);
          this._updateConnectionIndicator(true, data.ip);
        }
      });

      // Yeni Öğrenci Eklendiğinde / Güncellendiğinde
      this.eventSource.addEventListener('student_added', (e) => {
        const newStudent = JSON.parse(e.data).data;
        const idx = this.students.findIndex((s) => s.id === newStudent.id || (s.name && s.name.trim().toLowerCase() === (newStudent.name || '').trim().toLowerCase()));
        if (idx >= 0) {
          this.students[idx] = Object.assign(this.students[idx], newStudent);
        } else {
          this.students.unshift(newStudent);
        }
        if (typeof showToast === 'function') {
          showToast('👤 Öğrenci Senkronize Edildi', `${newStudent.name} panele başarıyla yansıdı.`);
        }
        if (typeof renderCurrentView === 'function') renderCurrentView();
      });

      // Öğrenci Silindiğinde
      this.eventSource.addEventListener('student_deleted', (e) => {
        const payload = JSON.parse(e.data).data;
        this.students = this.students.filter((s) => s.id !== payload.id);
        if (typeof renderCurrentView === 'function') renderCurrentView();
      });

      this.eventSource.onerror = () => {
        if (!this.db) {
          this.isLiveConnected = false;
          this._updateConnectionIndicator(false);
        }
      };
    } catch (err) {
      console.warn('Live stream init error:', err);
    }
  }

  _updateConnectionIndicator(isLive, ip) {
    const dot = document.querySelector('.status-dot');
    const label = document.querySelector('.cloud-status span');
    if (dot && label) {
      if (isLive) {
        dot.style.backgroundColor = '#10b981';
        dot.style.boxShadow = '0 0 10px #10b981';
        label.textContent = `Canlı Bağlantı Aktif (${ip || 'Bulut'})`;
      } else {
        dot.style.backgroundColor = '#f59e0b';
        dot.style.boxShadow = 'none';
        label.textContent = 'Çevrimdışı / Yerel Mod';
      }
    }
  }

  // 3. Tüm Verileri API'den veya Önbellekten Çek
  async loadAllFromApi() {
    try {
      const [resStd, resTch, resEval, resRec, resTsk] = await Promise.all([
        fetch(`${this.apiBase}/api/students`).then((r) => r.json()).catch(() => []),
        fetch(`${this.apiBase}/api/teachers`).then((r) => r.json()).catch(() => []),
        fetch(`${this.apiBase}/api/evaluations`).then((r) => r.json()).catch(() => []),
        fetch(`${this.apiBase}/api/recipes`).then((r) => r.json()).catch(() => []),
        fetch(`${this.apiBase}/api/tasks`).then((r) => r.json()).catch(() => []),
      ]);

      if (this.students.length === 0 && Array.isArray(resStd) && resStd.length > 0) {
        this.students = resStd;
      }
      this.teachers = Array.isArray(resTch) ? resTch : [];
      if (this.forms.length === 0 && Array.isArray(resEval) && resEval.length > 0) {
        this.forms = resEval;
      }
      if (this.recipes.length === 0 && Array.isArray(resRec) && resRec.length > 0) {
        this.recipes = resRec;
      }
      this.tasks = Array.isArray(resTsk) ? resTsk : [];

      if (this.teachers.length > 0 && !this.activeTeacherId) {
        this.activeTeacherId = this.teachers[0].id;
      }

      if (typeof setupTeacherSelector === 'function') setupTeacherSelector();
      if (typeof renderCurrentView === 'function') renderCurrentView();
    } catch (err) {
      console.warn('API fetch fallback to cache:', err);
    }
  }

  // Rol Yönetimi
  getCurrentRole() {
    return this.activeRole;
  }

  setCurrentRole(role) {
    this.activeRole = role;
  }

  getActiveTeacherId() {
    return this.activeTeacherId;
  }

  setActiveTeacherId(id) {
    this.activeTeacherId = id;
  }

  // Öğretmenler
  getTeachers() {
    return this.teachers;
  }

  getTeacherById(id) {
    return this.teachers.find((t) => t.id === id);
  }

  async addTeacher(teacher) {
    teacher.id = 'tch_' + Date.now();
    teacher.avatar = teacher.avatar || '👨‍🏫';
    teacher.assignedStudentIds = teacher.assignedStudentIds || [];
    this.teachers.push(teacher);

    fetch(`${this.apiBase}/api/teachers`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(teacher),
    }).catch(console.error);

    return teacher;
  }

  deleteTeacher(id) {
    this.teachers = this.teachers.filter((t) => t.id !== id);
  }

  // Öğrenciler
  getStudents() {
    return this.students;
  }

  getStudentById(id) {
    return this.students.find((s) => s.id === id);
  }

  getStudentsForTeacher(teacherId) {
    if (!teacherId || this.teachers.length === 0) return this.students;
    return this.students.filter((s) => !s.teacherId || s.teacherId === teacherId);
  }

  async addStudent(student) {
    student.id = student.id || ('std_' + Date.now());
    student.avatar = student.avatar || '🧒';
    student.streakDays = student.streakDays || 0;

    // Firebase Firestore'a anında kaydet
    if (this.db) {
      try {
        await this.db.collection('students').doc(student.id).set(student, { merge: true });
      } catch (e) {
        console.warn('Firestore addStudent error:', e);
      }
    }

    // Yerel API'ye de kaydet
    fetch(`${this.apiBase}/api/students`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(student),
    }).catch(console.error);

    return student;
  }

  async deleteStudent(id) {
    this.students = this.students.filter((s) => s.id !== id);

    // Firebase Firestore'dan anında sil
    if (this.db) {
      try {
        await this.db.collection('students').doc(id).delete();
      } catch (e) {
        console.warn('Firestore delete error:', e);
      }
    }

    try {
      await fetch(`${this.apiBase}/api/students/delete`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id }),
      });
    } catch (e) {
      console.warn('Student deletion server error:', e);
    }
  }

  // Formlar
  getForms() {
    return this.forms;
  }

  getFormById(id) {
    return this.forms.find((f) => f.id === id);
  }

  getFormsForTeacher(teacherId) {
    if (!teacherId || this.teachers.length === 0) return this.forms;
    const myStudents = this.getStudentsForTeacher(teacherId).map((s) => s.id);
    return this.forms.filter((f) => !f.studentId || myStudents.includes(f.studentId));
  }

  async saveReview(formId, teacherNote) {
    const form = this.forms.find((f) => f.id === formId);
    if (form) {
      form.status = 'reviewed';
      form.teacherNote = teacherNote;
    }

    if (this.db) {
      try {
        await this.db.collection('evaluations').doc(formId).update({
          status: 'reviewed',
          teacherNote: teacherNote
        });
      } catch (e) {
        console.warn('Firestore saveReview error:', e);
      }
    }

    fetch(`${this.apiBase}/api/evaluations/review`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: formId, teacherNote }),
    }).catch(console.error);
  }

  // Tarifler
  getRecipes() {
    return this.recipes;
  }

  getRecipeById(id) {
    return this.recipes.find((r) => r.id === id);
  }

  async addRecipe(recipe) {
    recipe.id = recipe.id || ('rec_' + Date.now());
    const existing = this.recipes.findIndex((r) => r.id === recipe.id);
    if (existing >= 0) {
      this.recipes[existing] = recipe;
    } else {
      this.recipes.unshift(recipe);
    }

    if (this.db) {
      try {
        await this.db.collection('recipes').doc(recipe.id).set(recipe, { merge: true });
      } catch (e) {
        console.warn('Firestore addRecipe error:', e);
      }
    }

    fetch(`${this.apiBase}/api/recipes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(recipe),
    }).catch(console.error);

    return recipe;
  }

  // Görevler
  getTasks() {
    return this.tasks;
  }

  async addTask(task) {
    task.id = task.id || ('tsk_' + Date.now());
    task.isCompleted = false;
    task.createdAt = new Date().toISOString();

    const existingIdx = this.tasks.findIndex((t) => t.id === task.id);
    if (existingIdx >= 0) {
      this.tasks[existingIdx] = task;
    } else {
      this.tasks.unshift(task);
    }

    // 1. Firebase Firestore'a kaydet (Buluta gönder)
    if (this.db) {
      try {
        await this.db.collection('tasks').doc(task.id).set(task, { merge: true });
        console.log('🚀 Görev Firebase Bulutuna kaydedildi:', task.title);
      } catch (e) {
        console.warn('Firestore addTask error:', e);
      }
    }

    // 2. Yerel API'ye de gönder
    fetch(`${this.apiBase}/api/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(task),
    }).catch(console.error);

    return task;
  }

  async toggleTaskCompletion(id) {
    const task = this.tasks.find((t) => t.id === id);
    if (task) {
      task.isCompleted = !task.isCompleted;
      if (this.db) {
        try {
          await this.db.collection('tasks').doc(id).update({ isCompleted: task.isCompleted });
        } catch (e) {
          console.warn('Firestore toggleTask error:', e);
        }
      }
    }
  }

  async deleteTask(id) {
    this.tasks = this.tasks.filter((t) => t.id !== id);
    if (this.db) {
      try {
        await this.db.collection('tasks').doc(id).delete();
      } catch (e) {
        console.warn('Firestore deleteTask error:', e);
      }
    }
  }
}

const dataService = new PanelDataService();
