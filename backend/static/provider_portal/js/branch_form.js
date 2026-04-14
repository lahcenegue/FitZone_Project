'use strict';

document.addEventListener("DOMContentLoaded", function() {

    /* ====================================================================
       1. FLOATING LABELS
       ==================================================================== */
    const floatContainers = document.querySelectorAll('.float-group');
    floatContainers.forEach(group => {
        const input = group.querySelector('input:not([type="hidden"]), select, textarea');
        if (input) {
            input.classList.add('float-input');
            if (!input.getAttribute('placeholder')) {
                input.setAttribute('placeholder', ' ');
            }
        }
    });

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
            const file = e.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    const preview = document.getElementById('logoPreview');
                    preview.src = e.target.result;
                    preview.classList.add('has-image');
                    const uploadIcon = document.getElementById('uploadIcon');
                    if(uploadIcon) uploadIcon.style.display = 'none';
                    const uploadText = document.getElementById('uploadText');
                    if(uploadText) uploadText.style.display = 'none';
                }
                reader.readAsDataURL(file);
            }
        });
    }

    /* ====================================================================
       3. SELECT2 INITIALIZATION
       ==================================================================== */
    if (typeof jQuery !== 'undefined' && $.fn.select2) {
        $('.select2-multi').select2({
            width: '100%',
            placeholder: function(){ return $(this).data('placeholder'); },
            allowClear: true
        });
    }

    /* ====================================================================
       4. PANORAMIC LEAFLET MAP & CITY FLY-TO
       ==================================================================== */
    const latInput = document.getElementById('id_latitude');
    const lngInput = document.getElementById('id_longitude');
    const addrInput = document.getElementById('id_address');
    const citySelect = document.getElementById('id_city');
    let map;
    let marker;
    
    if (latInput && lngInput && document.getElementById('panoramicMap')) {
        let initialLat = latInput.value ? parseFloat(latInput.value) : 24.7136;
        let initialLng = lngInput.value ? parseFloat(lngInput.value) : 46.6753;

        map = L.map('panoramicMap', { scrollWheelZoom: false }).setView([initialLat, initialLng], 14);
        
        L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
            attribution: '&copy; OpenStreetMap contributors &copy; CARTO',
            subdomains: 'abcd',
            maxZoom: 20
        }).addTo(map);

        marker = L.marker([initialLat, initialLng], {draggable: true}).addTo(map);

        function updateLocation(lat, lng) {
            latInput.value = lat.toFixed(6);
            lngInput.value = lng.toFixed(6);
            
            fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`)
                .then(res => res.json())
                .then(data => {
                    if(data && data.display_name && addrInput) {
                        addrInput.value = data.display_name;
                        addrInput.focus();
                        addrInput.blur(); 
                    }
                })
                .catch(err => console.error("Geocoding failed:", err));
        }

        map.on('click', function(e) {
            marker.setLatLng(e.latlng);
            updateLocation(e.latlng.lat, e.latlng.lng);
        });

        marker.on('dragend', function(e) {
            const position = marker.getLatLng();
            updateLocation(position.lat, position.lng);
        });
    }

    if (citySelect && map && marker) {
        citySelect.addEventListener('change', function(e) {
            const cityName = e.target.value;
            if (cityName) {
                fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${cityName}, Saudi Arabia`)
                .then(res => res.json())
                .then(data => {
                    if(data && data.length > 0) {
                        const lat = parseFloat(data[0].lat);
                        const lon = parseFloat(data[0].lon);
                        map.flyTo([lat, lon], 13, { duration: 1.5 });
                        marker.setLatLng([lat, lon]);
                        updateLocation(lat, lon);
                    }
                })
                .catch(err => console.error("City search failed:", err));
            }
        });
    }

    /* ====================================================================
       5. SMART SCHEDULE BUILDER ENGINE (THE COMMANDER LOGIC)
       ==================================================================== */
    const ScheduleEngine = {
        periods: [],
        daysMapping: {
            '0': 'Sun', '1': 'Mon', '2': 'Tue', '3': 'Wed', 
            '4': 'Thu', '5': 'Fri', '6': 'Sat'
        },
        
        init: function() {
            this.cacheDOM();
            if(!this.container) return;
            this.bindEvents();
            this.loadInitialData();
            this.render();
        },
        
        cacheDOM: function() {
            this.container = document.getElementById('scheduleBuilder');
            if(!this.container) return;
            
            this.dayPills = this.container.querySelectorAll('.day-pill');
            this.timeStart = document.getElementById('schedStart');
            this.timeEnd = document.getElementById('schedEnd');
            
            this.genderBlock = document.getElementById('periodGenderBlock');
            this.genderSelect = document.getElementById('schedGender');
            
            this.btnAdd = document.getElementById('btnAddPeriod');
            this.listContainer = document.getElementById('periodsContainer');
            this.hiddenInput = document.getElementById('id_schedule_data');
            this.form = document.getElementById('branchForm');
            
            this.globalGenderRadios = document.querySelectorAll('input[name="gender"]');
        },
        
        bindEvents: function() {
            this.dayPills.forEach(pill => {
                pill.addEventListener('click', (e) => {
                    e.target.classList.toggle('active');
                    this.validateInput();
                });
            });

            this.timeStart.addEventListener('input', () => this.validateInput());
            this.timeEnd.addEventListener('input', () => this.validateInput());

            this.btnAdd.addEventListener('click', (e) => {
                e.preventDefault();
                this.addPeriod();
            });

            this.globalGenderRadios.forEach(r => {
                r.addEventListener('change', () => {
                    this.adjustGenderUI();
                    this.render(); 
                });
            });

            if (this.form) {
                this.form.addEventListener('submit', () => this.serialize());
            }
        },

        loadInitialData: function() {
            if(this.hiddenInput && this.hiddenInput.value) {
                try {
                    this.periods = JSON.parse(this.hiddenInput.value) || [];
                } catch(e) {
                    this.periods = [];
                }
            }
            this.adjustGenderUI();
        },

        adjustGenderUI: function() {
            if(!this.genderBlock) return;
            const checkedGender = document.querySelector('input[name="gender"]:checked');
            const branchGender = checkedGender ? checkedGender.value.toLowerCase() : 'mixed';
            
            // Core Logic: Hide completely if it's not mixed/both
            const isMixed = branchGender === 'mixed' || branchGender === 'both' || branchGender === '';
            
            if(isMixed) {
                this.genderBlock.style.display = 'flex';
            } else {
                this.genderBlock.style.display = 'none';
            }
        },

        validateInput: function() {
            const activeDays = this.container.querySelectorAll('.day-pill.active').length;
            const hasStart = this.timeStart.value !== '';
            const hasEnd = this.timeEnd.value !== '';
            this.btnAdd.disabled = !(activeDays > 0 && hasStart && hasEnd);
        },

        addPeriod: function() {
            const selectedDays = Array.from(this.container.querySelectorAll('.day-pill.active')).map(p => p.dataset.day);
            const start = this.timeStart.value;
            const end = this.timeEnd.value;
            
            const checkedGender = document.querySelector('input[name="gender"]:checked');
            const branchGender = checkedGender ? checkedGender.value.toLowerCase() : 'mixed';
            const isMixed = branchGender === 'mixed' || branchGender === 'both' || branchGender === '';
            
            // If branch is single gender, force that gender. Otherwise use dropdown value.
            let gender = isMixed ? this.genderSelect.value : branchGender;

            const id = Date.now().toString(36) + Math.random().toString(36).substr(2);

            this.periods.push({ id: id, days: selectedDays, start: start, end: end, gender: gender });

            this.dayPills.forEach(p => p.classList.remove('active'));
            this.timeStart.value = '';
            this.timeEnd.value = '';
            this.validateInput();
            this.render();
        },

        removePeriod: function(id) {
            this.periods = this.periods.filter(p => p.id !== id);
            this.render();
            this.validateInput();
        },

        editPeriod: function(id) {
            const period = this.periods.find(p => p.id === id);
            if(!period) return;

            this.dayPills.forEach(p => {
                if (period.days.includes(p.dataset.day)) { p.classList.add('active'); } 
                else { p.classList.remove('active'); }
            });
            this.timeStart.value = period.start;
            this.timeEnd.value = period.end;
            
            if(this.genderBlock.style.display !== 'none') {
                this.genderSelect.value = period.gender;
            }

            this.removePeriod(id);
        },

        render: function() {
            this.listContainer.innerHTML = '';
            
            const checkedGender = document.querySelector('input[name="gender"]:checked');
            const branchGender = checkedGender ? checkedGender.value.toLowerCase() : 'mixed';
            const isMixed = branchGender === 'mixed' || branchGender === 'both' || branchGender === '';
            
            const sortedPeriods = [...this.periods].sort((a, b) => Math.min(...a.days) - Math.min(...b.days));

            if (isMixed) {
                const malePeriods = sortedPeriods.filter(p => p.gender === 'male' || p.gender === 'm' || p.gender === 'men');
                const femalePeriods = sortedPeriods.filter(p => p.gender === 'female' || p.gender === 'f' || p.gender === 'women');
                const bothPeriods = sortedPeriods.filter(p => p.gender === 'both' || p.gender === 'mixed');

                if (bothPeriods.length > 0) {
                    this.renderBox(bothPeriods, 'Both Schedule', 'both-col', this.listContainer);
                }

                if (malePeriods.length > 0 || femalePeriods.length > 0) {
                    const splitContainer = document.createElement('div');
                    splitContainer.className = 'schedule-split-layout';
                    
                    const maleCol = document.createElement('div');
                    maleCol.className = 'split-col male-col';
                    if (malePeriods.length > 0) {
                        this.renderBox(malePeriods, 'Men Schedule', 'male-col', maleCol);
                    }
                    
                    const femaleCol = document.createElement('div');
                    femaleCol.className = 'split-col female-col';
                    if (femalePeriods.length > 0) {
                        this.renderBox(femalePeriods, 'Women Schedule', 'female-col', femaleCol);
                    }
                    
                    splitContainer.appendChild(maleCol);
                    splitContainer.appendChild(femaleCol);
                    this.listContainer.appendChild(splitContainer);
                }

            } else {
                this.renderBox(sortedPeriods, '', 'none', this.listContainer, false);
            }
        },

        renderBox: function(periods, title, themeClass, parentContainer, showHeader = true) {
            if (periods.length === 0) return;

            if (showHeader) {
                const header = document.createElement('h4');
                header.className = `col-header`;
                
                // EXACT GENDER ICONS
                let icon = '';
                if(themeClass === 'male-col') {
                    // Mars (Male) Symbol
                    icon = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="10" cy="14" r="5"/><line x1="13.5" y1="10.5" x2="21" y2="3"/><polyline points="16 3 21 3 21 8"/></svg>';
                }
                if(themeClass === 'female-col') {
                    // Venus (Female) Symbol
                    icon = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="9" r="5"/><line x1="12" y1="14" x2="12" y2="22"/><line x1="9" y1="19" x2="15" y2="19"/></svg>';
                }
                if(themeClass === 'both-col') {
                    // Group Symbol
                    icon = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>';
                }

                header.innerHTML = `${icon} ${title}`;
                parentContainer.appendChild(header);
            }

            const list = document.createElement('div');
            list.style.display = 'flex';
            list.style.flexDirection = 'column';
            list.style.gap = '12px';

            periods.forEach(p => {
                const dayNames = p.days.map(d => this.daysMapping[d]).join(', ');
                
                const item = document.createElement('div');
                item.className = 'period-card';
                item.innerHTML = `
                    <div style="display:flex; flex-direction:column; gap:4px;">
                        <span class="period-days-text">${dayNames}</span>
                        <span class="time-text">
                            ${p.start} 
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--color-border)" stroke-width="2.5"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg> 
                            ${p.end}
                        </span>
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

                item.querySelector('.delete').addEventListener('click', (e) => { this.removePeriod(e.currentTarget.dataset.id); });
                item.querySelector('.edit').addEventListener('click', (e) => { this.editPeriod(e.currentTarget.dataset.id); });

                list.appendChild(item);
            });

            parentContainer.appendChild(list);
        },

        serialize: function() {
            if(this.hiddenInput) {
                const cleanData = this.periods.map(({id, ...rest}) => rest);
                this.hiddenInput.value = JSON.stringify(cleanData);
            }
        }
    };

    ScheduleEngine.init();
});