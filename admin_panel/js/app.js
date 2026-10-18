// ============================================================
// ÖZEL APP YÖNETİM & ÖĞRETMEN PORTALI - KULLANICI ARAYÜZÜ MOTORU
// ============================================================
// Temiz Başlangıç: Sahte öğrenci ve öğretmenler kaldırıldı.
// Kullanıcı kendi gerçek öğrencisini ve öğretmenini ekler.
// Mutfak bölümünde mobildeki Lezzet +1 Yemek Kitabının 21 tarifi listelenir.

document.addEventListener('DOMContentLoaded', () => {
  initApp();
});

let currentView = 'overview';
let activeFormForReview = null;
let currentIngredientsList = [];
let currentStepsList = [];

function initApp() {
  setupRoleSwitcher();
  setupNavigation();
  setupTeacherSelector();
  setupEventListeners();
  renderCurrentView();
  updateHeaderAndStats();
}

// ------------------------------------------------------------
// ROL & ÖĞRETMEN SEÇİCİ
// ------------------------------------------------------------
function setupRoleSwitcher() {
  const adminBtn = document.getElementById('roleAdminBtn');
  const teacherBtn = document.getElementById('roleTeacherBtn');
  const teacherSelectWrapper = document.getElementById('teacherSelectWrapper');

  const currentRole = dataService.getCurrentRole();
  if (currentRole === 'admin') {
    adminBtn.classList.add('active', 'admin');
    teacherBtn.classList.remove('active');
    teacherSelectWrapper.style.display = 'none';
  } else {
    teacherBtn.classList.add('active');
    adminBtn.classList.remove('active', 'admin');
    teacherSelectWrapper.style.display = 'flex';
  }

  adminBtn.addEventListener('click', () => {
    dataService.setCurrentRole('admin');
    adminBtn.classList.add('active', 'admin');
    teacherBtn.classList.remove('active');
    teacherSelectWrapper.style.display = 'none';
    showToast('👑 Yönetici (Admin) Moduna Geçildi', 'Tüm kurum verileri ve tarif yönetimi aktif.');
    renderCurrentView();
    updateHeaderAndStats();
  });

  teacherBtn.addEventListener('click', () => {
    dataService.setCurrentRole('teacher');
    teacherBtn.classList.add('active');
    adminBtn.classList.remove('active', 'admin');
    teacherSelectWrapper.style.display = 'flex';
    const activeTeacher = dataService.getTeacherById(dataService.getActiveTeacherId());
    showToast('🎓 Öğretmen Moduna Geçildi', activeTeacher ? `${activeTeacher.name} sınıfı görüntüleniyor.` : 'Lütfen bir öğretmen seçin.');
    renderCurrentView();
    updateHeaderAndStats();
  });
}

function setupTeacherSelector() {
  const select = document.getElementById('teacherSelect');
  const teachers = dataService.getTeachers();
  const activeId = dataService.getActiveTeacherId();

  if (teachers.length === 0) {
    select.innerHTML = '<option value="">Henüz Öğretmen Yok</option>';
    return;
  }

  select.innerHTML = teachers
    .map((t) => `<option value="${t.id}" ${t.id === activeId ? 'selected' : ''}>${t.avatar || '👨‍🏫'} ${t.name} (${t.title || 'Öğretmen'})</option>`)
    .join('');

  select.addEventListener('change', (e) => {
    dataService.setActiveTeacherId(e.target.value);
    const teacher = dataService.getTeacherById(e.target.value);
    if (teacher) {
      showToast('Öğretmen Değiştirildi', `${teacher.name} sınıfına geçildi.`);
    }
    renderCurrentView();
    updateHeaderAndStats();
  });
}

// ------------------------------------------------------------
// MENÜ VE NAVİGASYON
// ------------------------------------------------------------
function setupNavigation() {
  const navBtns = document.querySelectorAll('.nav-item[data-view]');
  navBtns.forEach((btn) => {
    btn.addEventListener('click', () => {
      const view = btn.getAttribute('data-view');
      navigateTo(view);
    });
  });

  const mobileBtn = document.getElementById('mobileMenuBtn');
  const sidebar = document.getElementById('sidebar');
  if (mobileBtn && sidebar) {
    mobileBtn.addEventListener('click', () => {
      sidebar.classList.toggle('mobile-open');
    });
  }
}

function navigateTo(viewName) {
  currentView = viewName;
  document.querySelectorAll('.nav-item').forEach((item) => {
    item.classList.toggle('active', item.getAttribute('data-view') === viewName);
  });
  document.querySelectorAll('.view-section').forEach((sec) => {
    sec.classList.toggle('active', sec.id === `view-${viewName}`);
  });

  const sidebar = document.getElementById('sidebar');
  if (sidebar) sidebar.classList.remove('mobile-open');

  renderCurrentView();
}

function renderCurrentView() {
  updateBadgeCounts();
  switch (currentView) {
    case 'overview':
      renderOverviewView();
      break;
    case 'evaluations':
      renderEvaluationsView();
      break;
    case 'recipes':
      renderRecipesView();
      break;
    case 'tasks':
      renderTasksView();
      break;
    case 'students':
      renderStudentsView();
      break;
    case 'teachers':
      renderTeachersView();
      break;
    case 'cloud':
      renderCloudView();
      break;
  }
}

function updateBadgeCounts() {
  const isTeacher = dataService.getCurrentRole() === 'teacher';
  const teacherId = dataService.getActiveTeacherId();
  const forms = isTeacher ? dataService.getFormsForTeacher(teacherId) : dataService.getForms();
  const pendingCount = forms.filter((f) => f.status === 'pending').length;

  const evalBadge = document.getElementById('evalBadge');
  if (evalBadge) {
    evalBadge.textContent = pendingCount;
    evalBadge.style.display = pendingCount > 0 ? 'inline-block' : 'none';
  }
}

function updateHeaderAndStats() {
  const role = dataService.getCurrentRole();
  const roleBadge = document.getElementById('userRoleBadge');
  if (roleBadge) {
    if (role === 'admin') {
      roleBadge.textContent = '👑 Kurum Yöneticisi (Admin)';
      roleBadge.className = 'status-badge published';
    } else {
      const t = dataService.getTeacherById(dataService.getActiveTeacherId());
      roleBadge.textContent = t ? `🎓 Öğretmen: ${t.name}` : '🎓 Öğretmen Modu (Öğretmen Ekleyin)';
      roleBadge.className = 'status-badge pending';
    }
  }
}

// ------------------------------------------------------------
// 1. GENEL BAKIŞ (OVERVIEW) GÖRÜNÜMÜ
// ------------------------------------------------------------
function renderOverviewView() {
  const isTeacher = dataService.getCurrentRole() === 'teacher';
  const teacherId = dataService.getActiveTeacherId();

  const students = isTeacher ? dataService.getStudentsForTeacher(teacherId) : dataService.getStudents();
  const forms = isTeacher ? dataService.getFormsForTeacher(teacherId) : dataService.getForms();
  const recipes = dataService.getRecipes();
  const tasks = dataService.getTasks();

  const pendingForms = forms.filter((f) => f.status === 'pending');
  const publishedRecipes = recipes.filter((r) => r.isPublishedToApp);

  const container = document.getElementById('overviewStatsGrid');
  container.innerHTML = `
    <div class="stat-card">
      <div class="stat-icon-box" style="background: rgba(37, 99, 235, 0.1); color: #2563eb;">👥</div>
      <div class="stat-info">
        <p>${isTeacher ? 'Sorumlu Öğrenciler' : 'Toplam Kayıtlı Öğrenci'}</p>
        <h3>${students.length} Öğrenci</h3>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon-box" style="background: rgba(217, 119, 6, 0.1); color: #d97706;">📋</div>
      <div class="stat-info">
        <p>İncelenecek Anketler</p>
        <h3>${pendingForms.length} Yeni Form</h3>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon-box" style="background: rgba(124, 58, 237, 0.1); color: #7c3aed;">🍳</div>
      <div class="stat-info">
        <p>Mutfak Kitaplığı (Lezzet +1)</p>
        <h3>${publishedRecipes.length} Aktif Tarif</h3>
      </div>
    </div>
    <div class="stat-card">
      <div class="stat-icon-box" style="background: rgba(5, 150, 105, 0.1); color: #059669;">🎯</div>
      <div class="stat-info">
        <p>Haftalık Görevler</p>
        <h3>${tasks.length} Görev</h3>
      </div>
    </div>
  `;

  // Son Gelen Anketler Tablosu
  const recentTable = document.getElementById('overviewRecentFormsTable');
  if (forms.length === 0) {
    recentTable.innerHTML = `
      <tr>
        <td colspan="5" style="text-align:center; padding:48px 20px; color:#64748b;">
          <div style="font-size:36px; margin-bottom:10px;">📋</div>
          <strong style="font-size:15px; display:block; color:#334155;">Henüz gelen anket bulunmuyor.</strong>
          <span style="font-size:13px;">Çocuklar mobil uygulamadan 'Okul, İşyeri veya Tüm Gün' formunu doldurup 'Öğretmenime Gönder' dediğinde burada görünecektir.</span>
        </td>
      </tr>
    `;
  } else {
    recentTable.innerHTML = forms.slice(0, 5).map((f) => `
      <tr>
        <td>
          <div style="display:flex; align-items:center; gap:10px;">
            <span style="font-size:22px;">${f.studentAvatar || '👦'}</span>
            <div>
              <strong>${f.studentName}</strong>
              <div style="font-size:12px; color:#64748b;">${f.mood || 'Genel'}</div>
            </div>
          </div>
        </td>
        <td>
          <span style="font-weight:600; color:#334155;">${f.formTitle}</span>
        </td>
        <td>${f.date} - ${f.time}</td>
        <td>
          <span class="status-badge ${f.status}">
            ${f.status === 'pending' ? '⏳ İncelenmedi' : '✅ İncelendi'}
          </span>
        </td>
        <td>
          <button class="btn btn-primary" onclick="openReviewModal('${f.id}')">
            🔍 İncele & Not Yaz
          </button>
        </td>
      </tr>
    `).join('');
  }
}

// ------------------------------------------------------------
// 2. GELEN ANKETLER (EVALUATIONS) GÖRÜNÜMÜ
// ------------------------------------------------------------
function renderEvaluationsView() {
  const isTeacher = dataService.getCurrentRole() === 'teacher';
  const teacherId = dataService.getActiveTeacherId();
  let forms = isTeacher ? dataService.getFormsForTeacher(teacherId) : dataService.getForms();

  const filterType = document.getElementById('evalFilterType').value;
  const filterStatus = document.getElementById('evalFilterStatus').value;
  const searchTerm = (document.getElementById('evalSearchInput').value || '').toLowerCase();

  if (filterType !== 'all') {
    forms = forms.filter((f) => f.formType === filterType);
  }
  if (filterStatus !== 'all') {
    forms = forms.filter((f) => f.status === filterStatus);
  }
  if (searchTerm) {
    forms = forms.filter((f) => (f.studentName || '').toLowerCase().includes(searchTerm) || (f.formTitle || '').toLowerCase().includes(searchTerm));
  }

  const tableBody = document.getElementById('evaluationsTableBody');
  if (forms.length === 0) {
    tableBody.innerHTML = `
      <tr>
        <td colspan="6" style="text-align:center; padding:60px 20px; color:#64748b;">
          <div style="font-size:40px; margin-bottom:12px;">📭</div>
          <strong style="font-size:16px; display:block; color:#334155;">Gelen Değerlendirme Formu Yok</strong>
          <span style="font-size:13px; max-width:480px; display:inline-block; margin-top:4px;">
            Çocuklar tablet uygulamasından günlük anketlerini tamamlayıp yolladıklarında otomatik olarak burada listelenecektir.
          </span>
        </td>
      </tr>
    `;
    return;
  }

  tableBody.innerHTML = forms.map((f) => `
    <tr>
      <td>
        <div style="display:flex; align-items:center; gap:10px;">
          <span style="font-size:24px;">${f.studentAvatar || '👦'}</span>
          <div>
            <strong>${f.studentName}</strong>
            <div style="font-size:12px; color:#64748b;">${f.mood || 'Belirtilmedi'}</div>
          </div>
        </div>
      </td>
      <td>
        <strong>${f.formTitle}</strong>
        <div style="font-size:12px; color:#64748b;">${f.answers ? f.answers.length : 0} Soru Yanıtlandı</div>
      </td>
      <td>${f.date} <br><span style="font-size:12px; color:#64748b;">${f.time}</span></td>
      <td>
        <span class="status-badge ${f.status}">
          ${f.status === 'pending' ? '⏳ Bekliyor' : '✅ İncelendi'}
        </span>
      </td>
      <td>
        <div style="max-width:240px; font-size:12px; color:#475569; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">
          ${f.teacherNote ? `💬 "${f.teacherNote}"` : '<em style="color:#94a3b8;">Not düşülmedi</em>'}
        </div>
      </td>
      <td>
        <button class="btn btn-primary" onclick="openReviewModal('${f.id}')">
          🔍 İncele & Değerlendir
        </button>
      </td>
    </tr>
  `).join('');
}

// ------------------------------------------------------------
// ANKET İNCELEME MODALI
// ------------------------------------------------------------
window.openReviewModal = function(formId) {
  const form = dataService.getFormById(formId);
  if (!form) return;
  activeFormForReview = form;

  document.getElementById('modalStudentName').textContent = form.studentName;
  document.getElementById('modalFormTitle').textContent = form.formTitle;
  document.getElementById('modalFormDate').textContent = `${form.date} Saat: ${form.time}`;
  document.getElementById('modalFormMood').textContent = `Duygu Durumu: ${form.mood || 'Belirtilmedi'}`;

  const listContainer = document.getElementById('modalQaList');
  listContainer.innerHTML = (form.answers || []).map((qa, idx) => `
    <div class="eval-qa-item">
      <div class="eval-question">${idx + 1}. ${qa.q}</div>
      <div class="eval-answer">${qa.a}</div>
    </div>
  `).join('');

  document.getElementById('modalTeacherNote').value = form.teacherNote || '';

  const modal = document.getElementById('reviewModal');
  modal.classList.add('active');
};

window.closeReviewModal = function() {
  document.getElementById('reviewModal').classList.remove('active');
  activeFormForReview = null;
};

window.saveFormReview = function() {
  if (!activeFormForReview) return;
  const note = document.getElementById('modalTeacherNote').value.trim();
  dataService.reviewForm(activeFormForReview.id, note);
  showToast('✅ Değerlendirme Kaydedildi', `${activeFormForReview.studentName} için öğretmen notu sisteme işlendi.`);
  closeReviewModal();
  renderCurrentView();
};

window.quickInsertNote = function(text) {
  const area = document.getElementById('modalTeacherNote');
  if (area.value) {
    area.value += ' ' + text;
  } else {
    area.value = text;
  }
};

window.copyReportForParent = function() {
  if (!activeFormForReview) return;
  const note = document.getElementById('modalTeacherNote').value.trim();
  const answersText = (activeFormForReview.answers || []).map((qa) => `• ${qa.q}\n  ↳ ${qa.a}`).join('\n\n');

  const textToCopy = `📋 *ÖZEL ADIMLAR AKADEMİ - GÜNLÜK DEĞERLENDİRME RAPORU*\n` +
    `👤 *Öğrenci:* ${activeFormForReview.studentName}\n` +
    `📅 *Tarih:* ${activeFormForReview.date} (${activeFormForReview.time})\n` +
    `📝 *Form:* ${activeFormForReview.formTitle}\n` +
    `😊 *Duygu Durumu:* ${activeFormForReview.mood || 'İyi'}\n\n` +
    `*ÖĞRENCİ YANITLARI:*\n${answersText}\n\n` +
    `🎓 *ÖĞRETMEN GERİ BİLDİRİMİ:* ${note || 'Öğrencimiz bugün yönergeleri çok güzel takip etti.'}\n\n` +
    `_ÖzelApp Eğitmen Paneli Aracılığıyla İletilmiştir._`;

  navigator.clipboard.writeText(textToCopy).then(() => {
    showToast('📋 Rapor Kopyalandı', 'Veliye WhatsApp veya SMS üzerinden yapıştırıp gönderebilirsiniz!');
  }).catch(() => {
    alert('Metin kopyalanamadı.');
  });
};

// ------------------------------------------------------------
// 3. MUTFAK & TARİF SİHİRBAZI (RECIPES - LEZZET +1 KİTABI)
// ------------------------------------------------------------
function renderRecipesView() {
  const recipes = dataService.getRecipes();
  const grid = document.getElementById('recipesGrid');

  if (recipes.length === 0) {
    grid.innerHTML = `<div style="grid-column: 1/-1; text-align:center; padding:40px; color:#64748b;">Henüz tarif yok. 'Yeni Tarif Ekle' butonuyla ekleyin.</div>`;
    return;
  }

  grid.innerHTML = recipes.map((r) => `
    <div class="recipe-card">
      <div class="recipe-image-wrap">
        <img src="${r.imageUrl || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600'}" alt="${r.title}">
        <div class="recipe-badge-top">${r.category}</div>
      </div>
      <div class="recipe-body">
        <div class="recipe-header-title">
          <span style="font-size:24px;">${r.icon || '🍳'}</span>
          <h4>${r.title}</h4>
        </div>
        <p class="recipe-desc">${r.description || r.subtitle || 'Lezzet +1 Kitabından resimli tarif.'}</p>
        
        <div class="recipe-meta-row">
          <span>⏱️ ${r.prepTime || '20 dk'}</span>
          <span>🔥 ${r.difficulty || 'Kolay'}</span>
          <span>🍽️ ${r.servings || r.portions || '4 Kişilik'}</span>
          <span>🪜 ${r.steps ? r.steps.length : 0} Adım</span>
        </div>

        <div class="recipe-actions">
          <label style="display:flex; align-items:center; gap:6px; cursor:pointer; font-size:13px; font-weight:600; color:${r.isPublishedToApp ? '#059669' : '#64748b'};">
            <input type="checkbox" ${r.isPublishedToApp ? 'checked' : ''} onchange="toggleRecipePublish('${r.id}')">
            ${r.isPublishedToApp ? '📱 Çocuk Ekranında Yayında' : '⏸️ Taslak'}
          </label>
          <div style="display:flex; gap:6px;">
            <button class="btn btn-outline" style="padding:4px 8px;" onclick="viewRecipeDetails('${r.id}')">📖 İncele</button>
            <button class="btn btn-danger-outline" style="padding:4px 8px;" onclick="deleteRecipe('${r.id}')">🗑️</button>
          </div>
        </div>
      </div>
    </div>
  `).join('');
}

window.toggleRecipePublish = function(id) {
  const r = dataService.togglePublishRecipe(id);
  if (r) {
    showToast(
      r.isPublishedToApp ? '🚀 Çocuk Ekranında Yayında!' : 'Tarif Gizlendi',
      `"${r.title}" ${r.isPublishedToApp ? 'mobil uygulamadaki Mutfak ekranında görünür.' : 'çocuk ekranından gizlendi.'}`
    );
    renderRecipesView();
  }
};

window.deleteRecipe = function(id) {
  if (confirm('Bu tarifi listeden kaldırmak istediğinize emin misiniz?')) {
    dataService.deleteRecipe(id);
    showToast('Tarif Silindi', 'Mutfak listesinden kaldırıldı.');
    renderRecipesView();
  }
};

window.viewRecipeDetails = function(id) {
  const r = dataService.getRecipeById(id);
  if (!r) return;
  alert(`🍳 ${r.title}\nKategori: ${r.category}\nSüre: ${r.prepTime}\nZorluk: ${r.difficulty}\n\nMalzemeler (${(r.ingredients || []).length}):\n${(r.ingredients || []).join('\n')}\n\nAdım Sayısı: ${(r.steps || []).length} adım`);
};

// Tarif Ekleme Modalı
window.openNewRecipeModal = function() {
  currentIngredientsList = [];
  currentStepsList = [];

  document.getElementById('recipeModalTitle').textContent = '🍳 Yeni Mutfak Tarifi Ekle';
  document.getElementById('recipeFormId').value = '';
  document.getElementById('recipeTitle').value = '';
  document.getElementById('recipeCategory').value = 'Çorbalar';
  document.getElementById('recipeDifficulty').value = 'Kolay';
  document.getElementById('recipePrepTime').value = '20 Dakika';
  document.getElementById('recipeCookTime').value = '20 Dakika';
  document.getElementById('recipeServings').value = '4 Kişilik';
  document.getElementById('recipeImageUrl').value = '';
  document.getElementById('recipeDescription').value = '';

  renderIngredientsChips();
  renderStepsInModal();

  document.getElementById('recipeModal').classList.add('active');
};

window.closeRecipeModal = function() {
  document.getElementById('recipeModal').classList.remove('active');
};

window.addIngredient = function() {
  const input = document.getElementById('ingredientInput');
  const val = input.value.trim();
  if (val) {
    currentIngredientsList.push(val);
    input.value = '';
    renderIngredientsChips();
  }
};

function renderIngredientsChips() {
  const container = document.getElementById('ingredientsChipsContainer');
  container.innerHTML = currentIngredientsList.map((ing, i) => `
    <span class="status-badge published" style="display:inline-flex; align-items:center; gap:6px; margin:3px;">
      ${ing}
      <span style="cursor:pointer; font-weight:bold;" onclick="removeIngredient(${i})">&times;</span>
    </span>
  `).join('');
}

window.removeIngredient = function(index) {
  currentIngredientsList.splice(index, 1);
  renderIngredientsChips();
};

window.addStepToRecipe = function() {
  const title = prompt('Adım Başlığı (Örn: Domatesleri Yıka):');
  if (!title) return;
  const instruction = prompt('Açıklama (Çocuğun göreceği metin):', title);
  const voice = prompt('Sesli Yönerge Metni (Robotun okuyacağı cümle):', instruction);
  const timer = parseInt(prompt('Süre Sayacı (Dakika):', '3') || '0', 10);

  currentStepsList.push({
    order: currentStepsList.length + 1,
    title: title,
    instruction: instruction,
    voicePrompt: voice,
    timerMinutes: timer,
  });

  renderStepsInModal();
};

function renderStepsInModal() {
  const container = document.getElementById('stepsContainerInModal');
  if (currentStepsList.length === 0) {
    container.innerHTML = `<p style="font-size:13px; color:#94a3b8; font-style:italic;">Henüz adım eklenmedi.</p>`;
    return;
  }

  container.innerHTML = currentStepsList.map((s, idx) => `
    <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px; padding:10px 14px; margin-bottom:8px; display:flex; justify-content:space-between; align-items:center;">
      <div>
        <strong>${idx + 1}. ${s.title}</strong>
        <div style="font-size:12px; color:#64748b;">${s.instruction} | ⏱️ ${s.timerMinutes || 0} dk | 🔊 "${s.voicePrompt}"</div>
      </div>
      <button class="btn btn-danger-outline" style="padding:2px 8px; font-size:11px;" onclick="removeStep(${idx})">Kaldır</button>
    </div>
  `).join('');
}

window.removeStep = function(idx) {
  currentStepsList.splice(idx, 1);
  renderStepsInModal();
};

window.saveRecipeForm = function() {
  const title = document.getElementById('recipeTitle').value.trim();
  if (!title) {
    alert('Lütfen tarif başlığını girin.');
    return;
  }

  const recipe = {
    id: document.getElementById('recipeFormId').value || 'rec_' + Date.now(),
    title: title,
    category: document.getElementById('recipeCategory').value,
    difficulty: document.getElementById('recipeDifficulty').value,
    prepTime: document.getElementById('recipePrepTime').value,
    cookTime: document.getElementById('recipeCookTime').value,
    servings: document.getElementById('recipeServings').value,
    portions: document.getElementById('recipeServings').value,
    imageUrl: document.getElementById('recipeImageUrl').value || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
    description: document.getElementById('recipeDescription').value,
    ingredients: currentIngredientsList.length > 0 ? currentIngredientsList : ['Temel Malzemeler'],
    steps: currentStepsList.length > 0 ? currentStepsList : [{ order: 1, title: 'Hazırlık', instruction: 'Malzemeleri hazırla.', timerMinutes: 5 }],
    isPublishedToApp: true,
  };

  dataService.saveRecipe(recipe);
  showToast('🎉 Tarif Kaydedildi!', `"${recipe.title}" mutfak kütüphanesine eklendi.`);
  closeRecipeModal();
  renderRecipesView();
};

// ------------------------------------------------------------
// 4. GÖREVLER & ÖDEVLER (TASKS)
// ------------------------------------------------------------
function renderTasksView() {
  const isTeacher = dataService.getCurrentRole() === 'teacher';
  const teacherId = dataService.getActiveTeacherId();
  let tasks = dataService.getTasks();

  if (isTeacher) {
    const students = dataService.getStudentsForTeacher(teacherId);
    const studentIds = students.map((s) => s.id);
    tasks = tasks.filter((t) => studentIds.includes(t.studentId));
  }

  const grid = document.getElementById('tasksGrid');
  if (tasks.length === 0) {
    grid.innerHTML = `
      <div style="grid-column: 1/-1; text-align:center; padding:60px 20px; color:#64748b;">
        <div style="font-size:40px; margin-bottom:12px;">🎯</div>
        <strong style="font-size:16px; display:block; color:#334155;">Henüz Tanımlı Görev Yok</strong>
        <span style="font-size:13px; max-width:480px; display:inline-block; margin-top:4px;">
          'Yeni Görev Ata' butonunu kullanarak öğrencilerinize özel günlük veya haftalık sorumluluk görevleri atayabilirsiniz.
        </span>
      </div>
    `;
    return;
  }

  grid.innerHTML = tasks.map((t) => `
    <div class="card-panel" style="padding:18px; margin-bottom:0; display:flex; flex-direction:column; justify-content:space-between; border-left: 4px solid ${t.isCompleted ? '#10b981' : '#3b82f6'};">
      <div>
        <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:8px;">
          <span style="font-size:28px;">${t.icon || '🎯'}</span>
          <span class="status-badge ${t.isCompleted ? 'reviewed' : 'pending'}">
            ${t.isCompleted ? '✅ Tamamlandı' : '⏳ Devam Ediyor'}
          </span>
        </div>
        <h4 style="font-family:var(--font-heading); font-size:16px; font-weight:700; margin-bottom:4px;">${t.title}</h4>
        <div style="font-size:12px; color:#64748b; margin-bottom:12px;">👤 Öğrenci: <strong>${t.studentName}</strong></div>
        <div style="font-size:12px; color:#475569; display:flex; gap:12px; margin-bottom:16px;">
          <span>📅 ${t.dueDate}</span>
          <span>⭐️ +${t.points || 15} Puan</span>
        </div>
      </div>
      <div style="display:flex; justify-content:space-between; align-items:center; border-top:1px solid #f1f5f9; padding-top:12px;">
        <button class="btn btn-outline" style="font-size:12px;" onclick="toggleTaskStatus('${t.id}')">
          ${t.isCompleted ? '↩️ Geri Al' : '✅ Tamamlandı Yap'}
        </button>
        <button class="btn btn-danger-outline" style="font-size:12px;" onclick="deleteTask('${t.id}')">🗑️ Sil</button>
      </div>
    </div>
  `).join('');
}

window.toggleTaskStatus = function(id) {
  const t = dataService.toggleTaskComplete(id);
  if (t) {
    showToast(t.isCompleted ? '🎉 Görev Tamamlandı!' : 'Görev Aktif Duruma Alındı', `${t.studentName} için güncellendi.`);
    renderTasksView();
  }
};

window.deleteTask = function(id) {
  dataService.deleteTask(id);
  showToast('Görev Silindi', 'Listeden kaldırıldı.');
  renderTasksView();
};

window.openNewTaskModal = function() {
  const select = document.getElementById('taskStudentSelect');
  const students = dataService.getStudents();

  if (students.length === 0) {
    alert('Görev atayabilmek için önce en az 1 öğrenci eklemelisiniz.');
    openNewStudentModal();
    return;
  }

  select.innerHTML = students.map((s) => `<option value="${s.id}">${s.avatar || '🧒'} ${s.name} (${s.diagnosis || 'Öğrenci'})</option>`).join('');

  document.getElementById('taskTitle').value = '';
  document.getElementById('taskDueDate').value = 'Bugün, 20:00';
  document.getElementById('taskPoints').value = '15';
  document.getElementById('taskModal').classList.add('active');
};

window.closeTaskModal = function() {
  document.getElementById('taskModal').classList.remove('active');
};

window.saveTaskForm = function() {
  const studentId = document.getElementById('taskStudentSelect').value;
  const student = dataService.getStudentById(studentId);
  const title = document.getElementById('taskTitle').value.trim();

  if (!title) {
    alert('Lütfen görev başlığı girin.');
    return;
  }

  const task = {
    studentId: student.id,
    studentName: student.name,
    title: title,
    category: document.getElementById('taskCategory').value,
    icon: document.getElementById('taskIcon').value,
    dueDate: document.getElementById('taskDueDate').value,
    priority: document.getElementById('taskPriority').value,
    points: parseInt(document.getElementById('taskPoints').value || '15', 10),
    assignedBy: dataService.getCurrentRole() === 'admin' ? 'Yönetici (Admin)' : 'Öğretmen',
  };

  dataService.addTask(task);
  showToast('🚀 Görev Çocuğun Ekranına Atandı!', `"${task.title}" görevi ${task.studentName} için hazır.`);
  closeTaskModal();
  renderTasksView();
};

// ------------------------------------------------------------
// 5. ÖĞRENCİLER (STUDENTS) GÖRÜNÜMÜ & EKLEME
// ------------------------------------------------------------
function renderStudentsView() {
  const isTeacher = dataService.getCurrentRole() === 'teacher';
  const teacherId = dataService.getActiveTeacherId();
  const students = isTeacher ? dataService.getStudentsForTeacher(teacherId) : dataService.getStudents();

  const grid = document.getElementById('studentsGrid');

  if (students.length === 0) {
    grid.innerHTML = `
      <div style="grid-column: 1/-1; text-align:center; padding:60px 20px; color:#64748b;">
        <div style="font-size:40px; margin-bottom:12px;">👥</div>
        <strong style="font-size:16px; display:block; color:#334155;">Henüz Kayıtlı Öğrenci Yok</strong>
        <span style="font-size:13px; max-width:480px; display:inline-block; margin-top:4px;">
          Sisteme gerçek öğrencilerinizi eklemek için yukarıdaki '➕ Yeni Öğrenci Ekle' butonuna tıklayın.
        </span>
      </div>
    `;
    return;
  }

  grid.innerHTML = students.map((s) => `
    <div class="card-panel" style="padding:20px; display:flex; flex-direction:column; justify-content:space-between;">
      <div>
        <div style="display:flex; align-items:center; gap:14px; margin-bottom:12px;">
          <div style="width:52px; height:52px; border-radius:50%; background:#eff6ff; display:flex; align-items:center; justify-content:center; font-size:28px;">
            ${s.avatar || '🧒'}
          </div>
          <div>
            <h4 style="font-family:var(--font-heading); font-size:17px; font-weight:700;">${s.name}</h4>
            <div style="font-size:12px; color:#64748b;">${s.age ? s.age + ' Yaşında | ' : ''}${s.diagnosis || 'Özel Gereksinim'}</div>
          </div>
        </div>

        <div style="background:#f8fafc; border-radius:8px; padding:10px 12px; font-size:13px; margin-bottom:14px; display:flex; flex-direction:column; gap:4px;">
          <div>👨‍👩‍👧 Veli: <strong>${s.parentName || 'Belirtilmedi'}</strong></div>
          <div>📞 Telefon: <strong>${s.parentPhone || 'Kayıtlı Değil'}</strong></div>
          <div>⏰ Son Etkinlik: <strong>${s.lastActive || 'Yeni Katıldı'}</strong></div>
        </div>
      </div>

      <div style="display:flex; gap:8px;">
        <button class="btn btn-primary" style="flex:1; font-size:12px;" onclick="openNewTaskForStudent('${s.id}')">
          🎯 Görev Ata
        </button>
        <button class="btn btn-danger-outline" style="font-size:12px;" onclick="deleteStudent('${s.id}')">
          🗑️ Sil
        </button>
      </div>
    </div>
  `).join('');
}

window.openNewStudentModal = function() {
  document.getElementById('studentName').value = '';
  document.getElementById('studentAge').value = '';
  document.getElementById('studentDiagnosis').value = '';
  document.getElementById('studentParentName').value = '';
  document.getElementById('studentParentPhone').value = '';
    
  // Öğretmen dropdownunu doldur
  const sel = document.getElementById('studentTeacherSelect');
  const teachers = dataService.getTeachers();
  sel.innerHTML = '<option value="">Atanmadı</option>' + teachers.map((t) => `<option value="${t.id}">${t.name}</option>`).join('');

  document.getElementById('studentModal').classList.add('active');
};

window.closeStudentModal = function() {
  document.getElementById('studentModal').classList.remove('active');
};

window.saveStudentForm = function() {
  const name = document.getElementById('studentName').value.trim();
  if (!name) {
    alert('Lütfen öğrenci adını soyadını girin.');
    return;
  }

  const student = {
    name: name,
    age: document.getElementById('studentAge').value.trim(),
    diagnosis: document.getElementById('studentDiagnosis').value.trim() || 'Özel Eğitim',
    parentName: document.getElementById('studentParentName').value.trim(),
    parentPhone: document.getElementById('studentParentPhone').value.trim(),
            teacherId: document.getElementById('studentTeacherSelect').value,
    avatar: '🧒',
  };

  dataService.addStudent(student);
  showToast('✅ Öğrenci Kaydedildi', `${student.name} başarıyla sisteme eklendi.`);
  closeStudentModal();
  renderCurrentView();
};

window.deleteStudent = function(id) {
  if (confirm('Bu öğrenciyi silmek istediğinize emin misiniz?')) {
    dataService.deleteStudent(id);
    showToast('Öğrenci Silindi', 'Kayıt kaldırıldı.');
    renderCurrentView();
  }
};

window.openNewTaskForStudent = function(studentId) {
  openNewTaskModal();
  document.getElementById('taskStudentSelect').value = studentId;
};

// ------------------------------------------------------------
// 6. ÖĞRETMENLER (TEACHERS) GÖRÜNÜMÜ & EKLEME
// ------------------------------------------------------------
function renderTeachersView() {
  const teachers = dataService.getTeachers();
  const allStudents = dataService.getStudents();
  const grid = document.getElementById('teachersGrid');

  if (teachers.length === 0) {
    grid.innerHTML = `
      <div style="grid-column: 1/-1; text-align:center; padding:60px 20px; color:#64748b;">
        <div style="font-size:40px; margin-bottom:12px;">👨‍🏫</div>
        <strong style="font-size:16px; display:block; color:#334155;">Henüz Kayıtlı Öğretmen Yok</strong>
        <span style="font-size:13px; max-width:480px; display:inline-block; margin-top:4px;">
          Sisteme kurumdaki öğretmenlerinizi ve uzmanlarınızı eklemek için yukarıdaki '➕ Yeni Öğretmen Ekle' butonuna tıklayın.
        </span>
      </div>
    `;
    return;
  }

  grid.innerHTML = teachers.map((t) => {
    const assigned = allStudents.filter((s) => s.teacherId === t.id || (t.assignedStudentIds || []).includes(s.id));
    return `
      <div class="card-panel" style="padding:20px;">
        <div style="display:flex; justify-content:space-between; align-items:flex-start;">
          <div style="display:flex; align-items:center; gap:14px; margin-bottom:12px;">
            <div style="width:52px; height:52px; border-radius:50%; background:#f5f3ff; display:flex; align-items:center; justify-content:center; font-size:28px;">
              ${t.avatar || '👨‍🏫'}
            </div>
            <div>
              <h4 style="font-family:var(--font-heading); font-size:17px; font-weight:700;">${t.name}</h4>
              <div style="font-size:12px; color:#7c3aed; font-weight:600;">${t.title || 'Özel Eğitim Öğretmeni'}</div>
              <div style="font-size:12px; color:#64748b;">${t.email || ''} ${t.phone ? ' | ' + t.phone : ''}</div>
            </div>
          </div>
          <button class="btn btn-danger-outline" style="font-size:11px; padding:4px 8px;" onclick="deleteTeacher('${t.id}')">🗑️</button>
        </div>

        <div style="border-top:1px solid #f1f5f9; padding-top:12px; margin-top:12px;">
          <strong style="font-size:13px; color:#334155;">Sorumlu Olduğu Öğrenciler (${assigned.length}):</strong>
          <div style="display:flex; flex-wrap:wrap; gap:6px; margin-top:8px;">
            ${assigned.length > 0 ? assigned.map((s) => `<span class="status-badge published">${s.avatar || '🧒'} ${s.name}</span>`).join('') : '<em style="font-size:12px; color:#94a3b8;">Henüz öğrenci atanmadı</em>'}
          </div>
        </div>
      </div>
    `;
  }).join('');
}

window.openNewTeacherModal = function() {
  document.getElementById('teacherName').value = '';
  document.getElementById('teacherTitle').value = 'Özel Eğitim Uzmanı';
  document.getElementById('teacherPhone').value = '';
  document.getElementById('teacherEmail').value = '';
  document.getElementById('teacherModal').classList.add('active');
};

window.closeTeacherModal = function() {
  document.getElementById('teacherModal').classList.remove('active');
};

window.saveTeacherForm = function() {
  const name = document.getElementById('teacherName').value.trim();
  if (!name) {
    alert('Lütfen öğretmen adını girin.');
    return;
  }

  const teacher = {
    name: name,
    title: document.getElementById('teacherTitle').value.trim(),
    phone: document.getElementById('teacherPhone').value.trim(),
    email: document.getElementById('teacherEmail').value.trim(),
    avatar: '👨‍🏫',
  };

  dataService.addTeacher(teacher);
  showToast('✅ Öğretmen Eklendi', `${teacher.name} sisteme dahil edildi.`);
  closeTeacherModal();
  setupTeacherSelector();
  renderCurrentView();
};

window.deleteTeacher = function(id) {
  if (confirm('Bu öğretmeni silmek istediğinize emin misiniz?')) {
    dataService.deleteTeacher(id);
    showToast('Öğretmen Silindi', 'Kayıt kaldırıldı.');
    setupTeacherSelector();
    renderCurrentView();
  }
};

// ------------------------------------------------------------
// 7. BULUT & FIREBASE KILAVUZU
// ------------------------------------------------------------
function renderCloudView() {}

window.resetToEmptyState = function() {
  if (confirm('Tüm öğrenci, öğretmen, anket ve görevler temizlensin mi? (Mutfak Lezzet +1 tarifleri kalacaktır)')) {
    dataService.clearAllToEmpty();
    showToast('Sıfırlandı', 'Tüm sahte veriler temizlendi, tertemiz sıfır ekran açıldı.');
    setupTeacherSelector();
    renderCurrentView();
  }
};

// ------------------------------------------------------------
// EVENT LISTENERS & TOAST
// ------------------------------------------------------------
function setupEventListeners() {
  const evalSearch = document.getElementById('evalSearchInput');
  const evalFilterType = document.getElementById('evalFilterType');
  const evalFilterStatus = document.getElementById('evalFilterStatus');

  if (evalSearch) evalSearch.addEventListener('input', renderEvaluationsView);
  if (evalFilterType) evalFilterType.addEventListener('change', renderEvaluationsView);
  if (evalFilterStatus) evalFilterStatus.addEventListener('change', renderEvaluationsView);
}

function showToast(title, message) {
  const toast = document.getElementById('toastNotification');
  if (!toast) return;

  document.getElementById('toastTitle').textContent = title;
  document.getElementById('toastMessage').textContent = message;

  toast.classList.add('show');
  setTimeout(() => {
    toast.classList.remove('show');
  }, 4000);
}
