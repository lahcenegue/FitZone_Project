'use strict';

document.addEventListener("DOMContentLoaded", function() {

    /* ====================================================================
       1. FLOATING LABELS (From Global)
       ==================================================================== */
    if (typeof window.initFloatingLabels === 'function') {
        window.initFloatingLabels();
    }

    const fileInput = document.querySelector('input[type="file"]');
    if(fileInput) fileInput.classList.add('django-hidden');

    const emergencySwitch = document.querySelector('input[name="is_temporarily_closed"]');
    if(emergencySwitch) emergencySwitch.classList.add('switch-danger');

    // Clean up "Mixed / Both" text from Django labels automatically
    document.querySelectorAll('.radio-card-content span').forEach(span => {
        if(span.textContent.includes('Mixed') || span.textContent.includes('Both')) {
            span.textContent = 'Both';
        }
    });

    /* ====================================================================
       2. LOGO PREVIEW
       ==================================================================== */
    if(fileInput) {
        fileInput.addEventListener('change', function(e) {
            const previewImg = document.getElementById('logoPreviewImg');
            const placeholder = document.getElementById('logoPlaceholder');
            const file = e.target.files[0];

            if (file) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    previewImg.src = e.target.result;
                    previewImg.classList.remove('django-hidden');
                    placeholder.classList.add('django-hidden');
                }
                reader.readAsDataURL(file);
            } else {
                previewImg.src = '';
                previewImg.classList.add('django-hidden');
                placeholder.classList.remove('django-hidden');
            }
        });
    }

    /* ====================================================================
       3. SMART SCHEDULE ENGINE
       ==================================================================== */
    const scheduleDataInput = document.querySelector('input[name="schedule_data"]');
    const scheduleList = document.getElementById('scheduleList');
    const btnAddPeriod = document.getElementById('btnAddPeriod');
    const periodModal = document.getElementById('periodModal');
    const btnCloseModal = document.getElementById('btnCloseModal');
    const btnSavePeriod = document.getElementById('btnSavePeriod');
    
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
        if (!scheduleList) return;
        scheduleList.innerHTML = '';
        
        if (periods.length === 0) {
            scheduleList.innerHTML = `<div style="color: var(--color-text-muted); font-size: 13px; text-align: center; padding: 20px; border: 1px dashed var(--color-border); border-radius: var(--radius-md);">No working hours defined yet. The branch will be considered closed.</div>`;
        } else {
            periods.forEach(p => {
                const div = document.createElement('div');
                div.className = 'period-card';
                div.innerHTML = `
                    <div>
                        <span class="period-days-text">${p.days.join(', ')}</span>
                        <div class="time-text">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                            ${p.start} - ${p.end}
                            <span style="background: var(--color-bg); padding: 2px 8px; border-radius: 12px; font-size: 11px; margin-inline-start: 8px;">${p.gender.toUpperCase()}</span>
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
                scheduleList.appendChild(div);
            });
        }
        
        if (scheduleDataInput) {
            scheduleDataInput.value = JSON.stringify(periods);
        }
    }

    if (scheduleList) {
        scheduleList.addEventListener('click', function(e) {
            const btn = e.target.closest('button');
            if (!btn) return;
            const id = btn.getAttribute('data-id');
            if (btn.classList.contains('delete')) {
                periods = periods.filter(p => p.id !== id);
                renderPeriods();
            } else if (btn.classList.contains('edit')) {
                const p = periods.find(x => x.id === id);
                if (p) openModal(p);
            }
        });
    }

    function openModal(period = null) {
        document.querySelectorAll('.day-chip').forEach(c => c.classList.remove('selected'));
        document.getElementById('timeStart').value = '';
        document.getElementById('timeEnd').value = '';
        
        // Auto-select gender based on branch target gender radio
        const selectedBranchGender = document.querySelector('input[name="gender"]:checked');
        const defaultGender = selectedBranchGender ? selectedBranchGender.value : 'both';
        
        let genderSelect = document.getElementById('periodGender');
        if (genderSelect) {
            genderSelect.value = defaultGender;
        }

        if (period) {
            editingId = period.id;
            period.days.forEach(d => {
                const chip = document.querySelector(`.day-chip[data-val="${d}"]`);
                if(chip) chip.classList.add('selected');
            });
            document.getElementById('timeStart').value = period.start;
            document.getElementById('timeEnd').value = period.end;
            if (genderSelect && period.gender) {
                genderSelect.value = period.gender;
            }
        } else {
            editingId = null;
        }
        periodModal.style.display = 'flex';
    }

    function closeModal() {
        periodModal.style.display = 'none';
    }

    if (btnAddPeriod) btnAddPeriod.addEventListener('click', () => openModal());
    if (btnCloseModal) btnCloseModal.addEventListener('click', closeModal);
    
    document.querySelectorAll('.day-chip').forEach(chip => {
        chip.addEventListener('click', function() {
            this.classList.toggle('selected');
        });
    });

    if (btnSavePeriod) {
        btnSavePeriod.addEventListener('click', function() {
            const selectedDays = Array.from(document.querySelectorAll('.day-chip.selected')).map(c => c.getAttribute('data-val'));
            const tStart = document.getElementById('timeStart').value;
            const tEnd = document.getElementById('timeEnd').value;
            const pGender = document.getElementById('periodGender').value;

            if (selectedDays.length === 0 || !tStart || !tEnd) {
                alert("Please select at least one day and specify start and end times.");
                return;
            }

            const newPeriod = {
                id: editingId || generateId(),
                days: selectedDays,
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
            closeModal();
        });
    }

    // Auto-update modal gender if branch gender changes
    document.querySelectorAll('input[name="gender"]').forEach(radio => {
        radio.addEventListener('change', function() {
            const pGender = document.getElementById('periodGender');
            if (pGender) pGender.value = this.value;
        });
    });

    /* ====================================================================
       4. MAP AND LOCATION LOGIC
       ==================================================================== */
    let map;
    let marker;

    window.initMap = function() {
        const latInput = document.querySelector('input[name="latitude"]');
        const lngInput = document.querySelector('input[name="longitude"]');
        const addressInput = document.querySelector('input[name="address"]');
        const citySelect = document.querySelector('select[name="city"]');
        
        if (!latInput || !lngInput) return;

        let initialLat = 24.7136;
        let initialLng = 46.6753;

        if (latInput.value && lngInput.value) {
            initialLat = parseFloat(latInput.value);
            initialLng = parseFloat(lngInput.value);
        }

        const mapOptions = {
            center: { lat: initialLat, lng: initialLng },
            zoom: 13,
            mapTypeControl: false,
            streetViewControl: false,
        };

        map = new google.maps.Map(document.getElementById("map"), mapOptions);

        marker = new google.maps.Marker({
            position: { lat: initialLat, lng: initialLng },
            map: map,
            draggable: true,
            animation: google.maps.Animation.DROP,
        });

        const geocoder = new google.maps.Geocoder();

        function updateLocation(latLng) {
            latInput.value = latLng.lat().toFixed(6);
            lngInput.value = latLng.lng().toFixed(6);

            geocoder.geocode({ location: latLng }, (results, status) => {
                if (status === "OK" && results[0]) {
                    addressInput.value = results[0].formatted_address;
                    let foundCity = false;
                    
                    for (let component of results[0].address_components) {
                        if (component.types.includes("locality") || component.types.includes("administrative_area_level_1")) {
                            const detectedCity = component.long_name;
                            for (let option of citySelect.options) {
                                if (detectedCity.includes(option.value) || option.value.includes(detectedCity)) {
                                    citySelect.value = option.value;
                                    foundCity = true;
                                    break;
                                }
                            }
                        }
                        if(foundCity) break;
                    }
                }
            });
        }

        map.addListener("click", (e) => {
            marker.setPosition(e.latLng);
            updateLocation(e.latLng);
        });

        marker.addListener("dragend", (e) => {
            updateLocation(e.latLng);
        });
    };

    if (typeof jQuery !== 'undefined' && $.fn.select2) {
        $('.select2-multi').select2({
            width: '100%',
            placeholder: ' '
        });
    }
});