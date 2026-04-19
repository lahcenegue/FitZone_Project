'use strict';

const SAUDI_CITIES_COORDS = {
    "riyadh": { lat: 24.7136, lng: 46.6753 },
    "jeddah": { lat: 21.4858, lng: 39.1925 },
    "mecca": { lat: 21.3891, lng: 39.8579 },
    "medina": { lat: 24.5247, lng: 39.5692 },
    "dammam": { lat: 26.4207, lng: 50.0888 },
    "khobar": { lat: 26.2172, lng: 50.1971 },
    "dhahran": { lat: 26.2361, lng: 50.1324 },
    "tabuk": { lat: 28.3835, lng: 36.5662 },
    "abha": { lat: 18.2164, lng: 42.5053 },
    "khamis_mushait": { lat: 18.3061, lng: 42.7392 },
    "hail": { lat: 27.5114, lng: 41.6907 },
    "najran": { lat: 17.5026, lng: 44.1322 },
    "jubail": { lat: 27.0051, lng: 49.6583 },
    "yanbu": { lat: 24.0244, lng: 38.1882 },
    "taif": { lat: 21.2643, lng: 40.4022 },
    "buraidah": { lat: 26.3259, lng: 43.9749 },
    "qatif": { lat: 26.5568, lng: 49.9959 },
    "hofuf": { lat: 25.3789, lng: 49.5855 },
    "jizan": { lat: 16.8892, lng: 42.5511 },
    "arar": { lat: 30.9753, lng: 41.0381 }
};

document.addEventListener("DOMContentLoaded", function() {

    if (typeof window.initFloatingLabels === 'function') window.initFloatingLabels();

    const fileInput = document.querySelector('input[type="file"]');
    if(fileInput) fileInput.classList.add('django-hidden');

    const emergencySwitch = document.querySelector('input[name="is_temporarily_closed"]');
    if(emergencySwitch) emergencySwitch.classList.add('switch-danger');

    document.querySelectorAll('.radio-card-content span').forEach(span => {
        if(span.textContent.includes('Mixed') || span.textContent.includes('Both')) {
            span.textContent = 'Both';
        }
    });

    if(fileInput) {
        fileInput.addEventListener('change', function(e) {
            const previewImg = document.getElementById('logoPreviewImg');
            const placeholder = document.getElementById('logoPlaceholder');
            const file = e.target.files[0];

            if (file) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    if (previewImg) {
                        previewImg.src = e.target.result;
                        previewImg.classList.remove('django-hidden');
                        previewImg.classList.add('has-image');
                    }
                    if (placeholder) placeholder.classList.add('django-hidden');
                }
                reader.readAsDataURL(file);
            } else {
                if (previewImg) {
                    previewImg.src = '';
                    previewImg.classList.add('django-hidden');
                    previewImg.classList.remove('has-image');
                }
                if (placeholder) placeholder.classList.remove('django-hidden');
            }
        });
    }

    /* ====================================================================
       SMART SCHEDULE ENGINE
       ==================================================================== */
    const scheduleDataInput = document.querySelector('input[name="schedule_data"]');
    const scheduleBuilder = document.getElementById('scheduleBuilder'); 
    const btnAddPeriod = document.getElementById('btnAddPeriod');
    
    let periods = [];
    let editingId = null;

    if (scheduleDataInput && scheduleDataInput.value) {
        try {
            periods = JSON.parse(scheduleDataInput.value);
            renderPeriods();
        } catch (e) {
            console.error("Invalid initial schedule data");
        }
    }

    function generateId() { return Math.random().toString(36).substr(2, 9); }

    function renderPeriods() {
        const cMale = document.getElementById('periodsContainerMale');
        const cFemale = document.getElementById('periodsContainerFemale');
        const cMixed = document.getElementById('periodsContainerMixed');

        if(cMale) cMale.innerHTML = '';
        if(cFemale) cFemale.innerHTML = '';
        if(cMixed) cMixed.innerHTML = '';

        let hasMixed = false;

        if (periods.length > 0) {
            periods.forEach(p => {
                const div = document.createElement('div');
                div.className = 'period-card';
                div.innerHTML = `
                    <div>
                        <span class="period-days-text">${p.days.join(', ')}</span>
                        <div class="time-text">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                            ${p.start} - ${p.end}
                        </div>
                    </div>
                    <div class="period-action-right">
                        <button type="button" class="btn-action-period edit" data-id="${p.id}" title="Edit">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                        </button>
                        <button type="button" class="btn-action-period delete" data-id="${p.id}" title="Remove">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                        </button>
                    </div>
                `;
                
                if (p.gender === 'men') {
                    if(cMale) cMale.appendChild(div);
                } else if (p.gender === 'women') {
                    if(cFemale) cFemale.appendChild(div);
                } else {
                    hasMixed = true;
                    if(cMixed) cMixed.appendChild(div);
                }
            });
        }
        
        if(cMale && cMale.innerHTML === '') cMale.innerHTML = `<div class="empty-state-small">No hours defined.</div>`;
        if(cFemale && cFemale.innerHTML === '') cFemale.innerHTML = `<div class="empty-state-small">No hours defined.</div>`;
        if(cMixed && cMixed.innerHTML === '') cMixed.innerHTML = `<div class="empty-state-small">No hours defined.</div>`;

        // CORE FIX: Only show Mixed Container if there are actual periods for it OR if gender is specifically set to Mixed
        const colMixed = document.getElementById('colMixed');
        const checkedRadio = document.querySelector('input[name="gender"]:checked');
        if (colMixed && checkedRadio) {
            if (checkedRadio.value === 'mixed') {
                colMixed.style.display = hasMixed ? 'flex' : 'none';
            } else {
                colMixed.style.display = 'none';
            }
        }
        
        if (scheduleDataInput) {
            scheduleDataInput.value = JSON.stringify(periods);
        }
    }

    if (scheduleBuilder) {
        scheduleBuilder.addEventListener('click', function(e) {
            const btn = e.target.closest('.btn-action-period');
            if (!btn) return;
            const id = btn.getAttribute('data-id');
            if (btn.classList.contains('delete')) {
                periods = periods.filter(p => p.id !== id);
                renderPeriods();
            } else if (btn.classList.contains('edit')) {
                const p = periods.find(x => x.id === id);
                if (p) populateBuilder(p);
            }
        });
    }

    // --- CORE FIX: Sync target gender exactly with HTML name ---
    function toggleScheduleGenderVisibility() {
        const checkedRadio = document.querySelector('input[name="gender"]:checked');
        const periodGenderBlock = document.getElementById('periodGenderBlock');
        const schedGenderSelect = document.getElementById('schedGender');
        
        const colMale = document.getElementById('colMale');
        const colFemale = document.getElementById('colFemale');
        const colMixed = document.getElementById('colMixed');
        const splitLayoutContainer = document.getElementById('splitLayoutContainer');

        if (!checkedRadio) return;
        const val = checkedRadio.value;

        if (val !== 'mixed') {
            if (periodGenderBlock) periodGenderBlock.style.display = 'none';
            if (schedGenderSelect) schedGenderSelect.value = val;
            
            if (val === 'men') {
                if(colMale) colMale.style.display = 'flex';
                if(colFemale) colFemale.style.display = 'none';
                if(colMixed) colMixed.style.display = 'none';
                if(splitLayoutContainer) splitLayoutContainer.style.gridTemplateColumns = '1fr';
            } else if (val === 'women') {
                if(colMale) colMale.style.display = 'none';
                if(colFemale) colFemale.style.display = 'flex';
                if(colMixed) colMixed.style.display = 'none';
                if(splitLayoutContainer) splitLayoutContainer.style.gridTemplateColumns = '1fr';
            }
        } else {
            if (periodGenderBlock) periodGenderBlock.style.display = 'flex';
            if(colMale) colMale.style.display = 'flex';
            if(colFemale) colFemale.style.display = 'flex';
            if(splitLayoutContainer) splitLayoutContainer.style.gridTemplateColumns = '1fr 1fr';
        }
        
        renderPeriods(); 
    }

    toggleScheduleGenderVisibility();

    document.querySelectorAll('input[name="gender"]').forEach(radio => {
        radio.addEventListener('change', toggleScheduleGenderVisibility);
    });

    function populateBuilder(period = null) {
        document.querySelectorAll('.day-pill').forEach(c => c.classList.remove('active'));
        const timeStart = document.getElementById('schedStart');
        const timeEnd = document.getElementById('schedEnd');
        if (timeStart) timeStart.value = '';
        if (timeEnd) timeEnd.value = '';
        
        toggleScheduleGenderVisibility(); 

        if (period) {
            editingId = period.id;
            const daysArr = period.days_values || period.days; 
            daysArr.forEach(d => {
                const chip = document.querySelector(`.day-pill[data-day="${d}"]`);
                if(chip) chip.classList.add('active');
            });
            if (timeStart) timeStart.value = period.start;
            if (timeEnd) timeEnd.value = period.end;
            
            const genderSelect = document.getElementById('schedGender');
            if (genderSelect && period.gender) {
                genderSelect.value = period.gender;
            }
        } else {
            editingId = null;
        }
        checkFormValidity();
    }

    document.querySelectorAll('.day-pill').forEach(chip => {
        chip.addEventListener('click', function() {
            this.classList.toggle('active');
            checkFormValidity();
        });
    });

    function checkFormValidity() {
        const timeStart = document.getElementById('schedStart');
        const timeEnd = document.getElementById('schedEnd');
        const hasSelectedDays = document.querySelectorAll('.day-pill.active').length > 0;
        
        if (btnAddPeriod) {
            if (hasSelectedDays && timeStart && timeStart.value && timeEnd && timeEnd.value) {
                btnAddPeriod.removeAttribute('disabled');
            } else {
                btnAddPeriod.setAttribute('disabled', 'disabled');
            }
        }
    }

    if (document.getElementById('schedStart')) document.getElementById('schedStart').addEventListener('input', checkFormValidity);
    if (document.getElementById('schedEnd')) document.getElementById('schedEnd').addEventListener('input', checkFormValidity);

    if (btnAddPeriod) {
        btnAddPeriod.addEventListener('click', function(e) {
            e.preventDefault(); 
            if (this.hasAttribute('disabled')) return; 

            const selectedDaysElements = Array.from(document.querySelectorAll('.day-pill.active'));
            const selectedDaysText = selectedDaysElements.map(c => c.textContent.trim());
            const selectedDaysVals = selectedDaysElements.map(c => c.getAttribute('data-day'));
            
            const tStart = document.getElementById('schedStart').value;
            const tEnd = document.getElementById('schedEnd').value;
            const pGender = document.getElementById('schedGender') ? document.getElementById('schedGender').value : 'mixed';

            const newPeriod = {
                id: editingId || generateId(),
                days: selectedDaysText, 
                days_values: selectedDaysVals, 
                start: tStart,
                end: tEnd,
                gender: pGender
            };

            if (editingId) {
                const idx = periods.findIndex(p => p.id === editingId);
                if (idx > -1) periods[idx] = newPeriod;
            } else {
                periods.push(newPeriod);
            }

            renderPeriods();
            
            document.querySelectorAll('.day-pill').forEach(c => c.classList.remove('active'));
            if (document.getElementById('schedStart')) document.getElementById('schedStart').value = '';
            if (document.getElementById('schedEnd')) document.getElementById('schedEnd').value = '';
            checkFormValidity();
            editingId = null;
        });
    }

    /* ====================================================================
       MAP AND LOCATION LOGIC
       ==================================================================== */
    const mapContainer = document.getElementById("panoramicMap");
    if (mapContainer) {
        const latInput = document.querySelector('input[name="latitude"]');
        const lngInput = document.querySelector('input[name="longitude"]');
        const addressInput = document.querySelector('input[name="address"]');
        const citySelect = document.querySelector('select[name="city"]');
        
        if (latInput && lngInput) {
            let initialLat = 24.7136;
            let initialLng = 46.6753;

            if (latInput.value && lngInput.value) {
                initialLat = parseFloat(latInput.value);
                initialLng = parseFloat(lngInput.value);
            }

            const map = L.map('panoramicMap').setView([initialLat, initialLng], 13);

            L.tileLayer('https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', {
                maxZoom: 20,
                attribution: '&copy; Google Maps'
            }).addTo(map);

            const marker = L.marker([initialLat, initialLng], {
                draggable: true
            }).addTo(map);

            async function updateLocation(lat, lng) {
                latInput.value = lat.toFixed(6);
                lngInput.value = lng.toFixed(6);

                try {
                    const response = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1`);
                    const data = await response.json();

                    if (data && data.display_name && addressInput) {
                        addressInput.value = data.display_name;
                    }
                } catch (error) {
                    console.error("Reverse geocoding failed:", error);
                }
            }

            map.on('click', function(e) {
                marker.setLatLng(e.latlng);
                updateLocation(e.latlng.lat, e.latlng.lng);
            });

            marker.on('dragend', function(e) {
                const position = marker.getLatLng();
                updateLocation(position.lat, position.lng);
            });
            
            if (citySelect) {
                $(citySelect).on('select2:select', function(e) {
                    const cityKey = e.target.value; 
                    if (!cityKey || !SAUDI_CITIES_COORDS[cityKey]) return;

                    const coords = SAUDI_CITIES_COORDS[cityKey];
                    map.flyTo([coords.lat, coords.lng], 13);
                    marker.setLatLng([coords.lat, coords.lng]);
                    
                    latInput.value = coords.lat.toFixed(6);
                    lngInput.value = coords.lng.toFixed(6);
                    updateLocation(coords.lat, coords.lng);
                });
            }
        }
    }

    /* ====================================================================
       SELECT2 INITIALIZATION
       ==================================================================== */
    if (typeof jQuery !== 'undefined' && $.fn.select2) {
        $('select[name="city"]').select2({
            width: '100%',
            placeholder: ' ',
            allowClear: false, 
            theme: "default"
        });
        
        $('select[name="sports"], select[name="amenities"], select[name="branches"]').select2({
            width: '100%',
            placeholder: ' ',
            allowClear: true,
            theme: "default" 
        });
    }
});