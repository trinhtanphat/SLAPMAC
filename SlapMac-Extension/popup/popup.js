// SlapMac Extension - Popup Controller
document.addEventListener('DOMContentLoaded', async () => {
  const GITHUB_REPO = 'trinhtanphat/SLAPMAC';
  const RELEASES_URL = 'https://github.com/trinhtanphat/SLAPMAC/releases/latest';
  const { languageOptions: LANGUAGE_OPTIONS, translations: I18N } = await loadI18nConfig();

  // DOM Elements
  const toggleEnabled = document.getElementById('toggle-enabled');
  const statusText = document.getElementById('status-text');
  const statusIndicator = document.getElementById('status-indicator');
  const statusLabel = document.getElementById('status-label');
  const slapCountEl = document.getElementById('slap-count');
  const detectionMode = document.getElementById('detection-mode');
  const sensitivitySlider = document.getElementById('sensitivity');
  const sensitivityValue = document.getElementById('sensitivity-value');
  const volumeSlider = document.getElementById('volume');
  const volumeValue = document.getElementById('volume-value');
  const cooldownSlider = document.getElementById('cooldown');
  const cooldownValue = document.getElementById('cooldown-value');
  const languageSelect = document.getElementById('language-select');
  const testSoundBtn = document.getElementById('test-sound');
  const currentVersionEl = document.getElementById('current-version');
  const versionTextEl = document.getElementById('version-text');
  const updateStatusEl = document.getElementById('update-status');
  const checkUpdateBtn = document.getElementById('check-update');
  const updateNowBtn = document.getElementById('update-now');
  const showDonateBtn = document.getElementById('show-donate');
  const donateModal = document.getElementById('donate-modal');
  const closeDonateBtn = document.getElementById('close-donate');

  let latestTag = null;
  const currentVersion = chrome.runtime.getManifest().version;

  // State
  let state = await getState();
  let detector = null;

  // Initialize UI from state
  buildLanguageOptions();
  updateUI(state);

  // Start detection if enabled
  if (state.enabled) {
    startDetection(state);
  }

  // Event Listeners
  toggleEnabled.addEventListener('change', async () => {
    state.enabled = toggleEnabled.checked;
    await saveState(state);
    updateUI(state);

    if (state.enabled) {
      startDetection(state);
    } else {
      stopDetection();
    }
  });

  detectionMode.addEventListener('change', async () => {
    state.detectionMode = detectionMode.value;
    await saveState(state);
    if (state.enabled) {
      stopDetection();
      startDetection(state);
    }
  });

  sensitivitySlider.addEventListener('input', async () => {
    state.sensitivity = parseFloat(sensitivitySlider.value);
    sensitivityValue.textContent = state.sensitivity.toFixed(1);
    await saveState(state);
  });

  volumeSlider.addEventListener('input', async () => {
    state.volume = parseFloat(volumeSlider.value);
    volumeValue.textContent = Math.round(state.volume * 100) + '%';
    await saveState(state);
  });

  cooldownSlider.addEventListener('input', async () => {
    state.cooldown = parseInt(cooldownSlider.value);
    cooldownValue.textContent = state.cooldown + 'ms';
    await saveState(state);
  });

  languageSelect.addEventListener('change', async () => {
    state.language = languageSelect.value;
    await saveState(state);
    applyLanguage();
  });

  testSoundBtn.addEventListener('click', () => {
    playSound(state.volume);
    animateSlap();
  });

  checkUpdateBtn.addEventListener('click', () => {
    checkForUpdates(true);
  });

  updateNowBtn.addEventListener('click', () => {
    chrome.tabs.create({ url: RELEASES_URL });
  });

  showDonateBtn.addEventListener('click', () => {
    donateModal.classList.add('modal-open');
  });

  closeDonateBtn.addEventListener('click', () => {
    donateModal.classList.remove('modal-open');
  });

  donateModal.addEventListener('click', (e) => {
    if (e.target === donateModal) {
      donateModal.classList.remove('modal-open');
    }
  });

  // Functions
  function updateUI(s) {
    if (!s.language) s.language = 'en';
    toggleEnabled.checked = s.enabled;
    statusText.textContent = s.enabled ? t('enabled') : t('disabled');
    statusIndicator.className = 'status-indicator ' + (s.enabled ? 'listening' : 'disabled');
    statusLabel.textContent = s.enabled ? t('listening') : t('paused');
    slapCountEl.textContent = s.slapCount || 0;
    detectionMode.value = s.detectionMode || 'motion';
    languageSelect.value = s.language;
    sensitivitySlider.value = s.sensitivity;
    sensitivityValue.textContent = s.sensitivity.toFixed(1);
    volumeSlider.value = s.volume;
    volumeValue.textContent = Math.round(s.volume * 100) + '%';
    cooldownSlider.value = s.cooldown;
    cooldownValue.textContent = s.cooldown + 'ms';
    applyLanguage();
  }

  function t(key) {
    const dict = I18N[state.language] || I18N.en;
    return dict[key] || I18N.en[key] || key;
  }

  function tf(key, vars) {
    let text = t(key);
    Object.entries(vars || {}).forEach(([k, v]) => {
      text = text.replace(`{${k}}`, String(v));
    });
    return text;
  }

  function flagEmoji(countryCode) {
    return countryCode.toUpperCase().replace(/./g, c => String.fromCodePoint(127397 + c.charCodeAt()));
  }

  function buildLanguageOptions() {
    languageSelect.innerHTML = '';
    for (const item of LANGUAGE_OPTIONS) {
      const option = document.createElement('option');
      option.value = item.code;
      option.textContent = `${flagEmoji(item.flag)} ${item.label}`;
      languageSelect.appendChild(option);
    }
  }

  async function loadI18nConfig() {
    const fallback = {
      languageOptions: [{ code: 'en', label: 'English', flag: 'US' }],
      translations: {
        en: {
          subtitleMain: 'Tap your laptop, hear sounds!',
          subtitleWarning: '⚠ 18+ content warning',
          language: 'Language',
          enabled: 'Enabled',
          disabled: 'Disabled',
          listening: 'Listening for taps...',
          paused: 'Detection paused',
          totalSlaps: 'Total Slaps',
          detectionMode: 'Detection Mode',
          micMode: 'Microphone (Desktop)',
          motionMode: 'Motion Sensor (Mobile)',
          sensitivity: 'Sensitivity',
          volume: 'Volume',
          cooldown: 'Cooldown',
          testSound: '🔊 Test Sound',
          currentVersion: 'Current Version',
          checkUpdate: 'Check Update',
          updateNow: 'Update Now',
          donate: '☕ Support / Donate',
          keepOpen: '⚠ Keep popup open for detection to work',
          checkingTags: 'Checking GitHub tags...',
          noTags: 'No release tags found.',
          newVersion: 'New version available: {tag}',
          upToDate: 'Up to date ({tag}).',
          upToDateYou: "You're up to date ({tag}).",
          updateFailed: 'Update check failed. Try again later.',
          motionDenied: 'Motion permission denied',
          motionUnavailable: 'Motion not available, try Microphone mode',
          micListening: '🎤 Listening via microphone...',
          micDenied: 'Microphone permission denied'
        }
      }
    };

    try {
      const response = await fetch(chrome.runtime.getURL('popup/i18n.json'));
      if (!response.ok) return fallback;
      const data = await response.json();
      if (!data || !Array.isArray(data.languageOptions) || !data.translations || !data.translations.en) {
        return fallback;
      }
      return data;
    } catch {
      return fallback;
    }
  }

  function applyLanguage() {
    document.getElementById('subtitle-main').textContent = t('subtitleMain');
    document.getElementById('subtitle-warning').textContent = t('subtitleWarning');
    document.getElementById('language-label').textContent = t('language');
    document.getElementById('counter-label').textContent = t('totalSlaps');
    document.getElementById('label-detection-mode').textContent = t('detectionMode');
    document.getElementById('option-microphone').textContent = t('micMode');
    document.getElementById('option-motion').textContent = t('motionMode');
    document.getElementById('label-sensitivity').textContent = t('sensitivity');
    document.getElementById('label-volume').textContent = t('volume');
    document.getElementById('label-cooldown').textContent = t('cooldown');
    document.getElementById('test-sound-text').textContent = t('testSound');
    document.getElementById('update-label').textContent = t('currentVersion');
    document.getElementById('check-update').textContent = t('checkUpdate');
    document.getElementById('update-now').textContent = t('updateNow');
    document.getElementById('donate-btn-text').textContent = t('donate');
    document.getElementById('footer-keep-open').textContent = t('keepOpen');

    statusText.textContent = state.enabled ? t('enabled') : t('disabled');
    if (statusIndicator.classList.contains('disabled')) {
      statusLabel.textContent = t('paused');
    }

    currentVersionEl.textContent = 'v' + currentVersion;
    versionTextEl.textContent = 'v' + currentVersion + ' • Free & Open Source';
  }

  function animateSlap() {
    const counter = document.querySelector('.counter-value');
    counter.classList.remove('bump');
    // Reflow ensures animation can replay when taps happen quickly.
    void counter.offsetWidth;
    counter.classList.add('bump');
    setTimeout(() => {
      counter.classList.remove('bump');
    }, 150);
  }

  // Detection
  let lastSlapTime = 0;

  function startDetection(s) {
    stopDetection();

    if (s.detectionMode === 'motion') {
      startMotionDetection(s);
    } else {
      startMicrophoneDetection(s);
    }
  }

  function stopDetection() {
    if (detector) {
      detector.stop();
      detector = null;
    }
  }

  // Motion detection using DeviceMotion API
  function startMotionDetection(s) {
    // Request permission on iOS/newer browsers
    if (typeof DeviceMotionEvent !== 'undefined' && typeof DeviceMotionEvent.requestPermission === 'function') {
      DeviceMotionEvent.requestPermission().then(permission => {
        if (permission === 'granted') {
          setupMotionListener(s);
        }
      }).catch(() => {
        statusLabel.textContent = t('motionDenied');
        statusIndicator.className = 'status-indicator disabled';
      });
    } else if (typeof DeviceMotionEvent !== 'undefined') {
      setupMotionListener(s);
    } else {
      statusLabel.textContent = t('motionUnavailable');
      statusIndicator.className = 'status-indicator disabled';
    }
  }

  function setupMotionListener(s) {
    const handler = (event) => {
      if (!state.enabled) return;

      const acc = event.accelerationIncludingGravity;
      if (!acc) return;

      const magnitude = Math.sqrt(
        (acc.x || 0) ** 2 +
        (acc.y || 0) ** 2 +
        (acc.z || 0) ** 2
      );

      // Subtract gravity (~9.8) and check threshold
      const impact = Math.abs(magnitude - 9.8);
      const threshold = 6.0 / state.sensitivity;

      if (impact > threshold) {
        const now = Date.now();
        if (now - lastSlapTime > state.cooldown) {
          lastSlapTime = now;
          onSlapDetected();
        }
      }
    };

    window.addEventListener('devicemotion', handler);

    detector = {
      stop: () => window.removeEventListener('devicemotion', handler)
    };
  }

  // Microphone detection with adaptive baseline (matches Windows/Linux algorithm)
  function startMicrophoneDetection(s) {
    navigator.mediaDevices.getUserMedia({ audio: true }).then(stream => {
      const audioContext = new AudioContext();
      const source = audioContext.createMediaStreamSource(stream);
      const analyser = audioContext.createAnalyser();
      analyser.fftSize = 256;

      source.connect(analyser);

      const dataArray = new Uint8Array(analyser.frequencyBinCount);
      let running = true;

      // Adaptive baseline calibration
      let baseline = 0;
      let calibrationSamples = 0;
      const calibrationTotal = 30;
      let inSuppression = false;
      let suppressionEndTime = 0;
      let recalibrationCount = 0;
      const recalibrationTotal = 20;

      const check = () => {
        if (!running) return;
        if (!state.enabled) {
          setTimeout(check, 500);
          return;
        }

        analyser.getByteFrequencyData(dataArray);

        // Calculate RMS-like average
        let sum = 0;
        for (let i = 0; i < dataArray.length; i++) {
          sum += dataArray[i];
        }
        const avg = sum / dataArray.length;

        // Calibration phase
        if (calibrationSamples < calibrationTotal) {
          baseline = Math.max(baseline, avg);
          calibrationSamples++;
          requestAnimationFrame(check);
          return;
        }

        const now = Date.now();

        // Post-suppression recalibration
        if (inSuppression && now >= suppressionEndTime) {
          inSuppression = false;
          recalibrationCount = 0;
        }

        if (!inSuppression && recalibrationCount < recalibrationTotal) {
          baseline = baseline * 0.9 + avg * 0.1;
          recalibrationCount++;
          requestAnimationFrame(check);
          return;
        }

        // Slowly adapt baseline
        baseline = baseline * 0.98 + avg * 0.02;

        // Detection threshold
        const threshold = (baseline + 30) / state.sensitivity;

        if (avg > threshold) {
          // Extended suppression: 1 slap = 1 sound
          const suppressionMs = Math.max(state.cooldown * 2, 3000);
          if (now - lastSlapTime >= suppressionMs) {
            lastSlapTime = now;
            inSuppression = true;
            suppressionEndTime = now + suppressionMs;
            onSlapDetected();
          }
        }

        requestAnimationFrame(check);
      };

      check();

      detector = {
        stop: () => {
          running = false;
          stream.getTracks().forEach(t => t.stop());
          audioContext.close();
        }
      };

      statusLabel.textContent = t('micListening');
    }).catch(() => {
      statusLabel.textContent = t('micDenied');
      statusIndicator.className = 'status-indicator disabled';
    });
  }

  async function onSlapDetected() {
    state.slapCount = (state.slapCount || 0) + 1;
    slapCountEl.textContent = state.slapCount;
    await saveState(state);

    playSound(state.volume);
    animateSlap();

    // Send to background
    chrome.runtime.sendMessage({ type: 'INCREMENT_SLAP' });
  }

  function parseSemver(version) {
    const parts = String(version || '').split('.').map(n => parseInt(n, 10));
    return [parts[0] || 0, parts[1] || 0, parts[2] || 0];
  }

  function compareVersions(a, b) {
    const av = parseSemver(a);
    const bv = parseSemver(b);
    for (let i = 0; i < 3; i++) {
      if (av[i] > bv[i]) return 1;
      if (av[i] < bv[i]) return -1;
    }
    return 0;
  }

  async function checkForUpdates(manual) {
    try {
      updateStatusEl.textContent = t('checkingTags');
      checkUpdateBtn.disabled = true;

      const response = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/tags?per_page=20`, {
        headers: { 'Accept': 'application/vnd.github+json' }
      });

      if (!response.ok) {
        throw new Error('HTTP ' + response.status);
      }

      const tags = await response.json();
      const versionTags = tags
        .map(t => String(t.name || '').trim())
        .filter(name => /^v?\d+\.\d+\.\d+$/.test(name));

      if (versionTags.length === 0) {
        updateStatusEl.textContent = t('noTags');
        updateNowBtn.disabled = true;
        return;
      }

      latestTag = versionTags[0];
      const latestVersion = latestTag.replace(/^v/, '');
      const cmp = compareVersions(latestVersion, currentVersion);

      if (cmp > 0) {
        updateStatusEl.textContent = tf('newVersion', { tag: latestTag });
        updateNowBtn.disabled = false;
      } else {
        updateStatusEl.textContent = manual
          ? tf('upToDateYou', { tag: latestTag })
          : tf('upToDate', { tag: latestTag });
        updateNowBtn.disabled = true;
      }
    } catch (err) {
      updateStatusEl.textContent = t('updateFailed');
      updateNowBtn.disabled = true;
      console.warn('[SlapMac] Update check error:', err);
    } finally {
      checkUpdateBtn.disabled = false;
    }
  }

  // Audio playback
  const audioFiles = ['moan-female-active.mp3', 'gentle-feminine-groan.mp3'];

  function playSound(volume) {
    const file = audioFiles[Math.floor(Math.random() * audioFiles.length)];
    const audioUrl = chrome.runtime.getURL('audio/' + file);
    const audio = new Audio(audioUrl);
    audio.volume = volume;
    audio.play().catch(() => {
      console.log('[SlapMac] Audio playback failed');
    });
  }

  // State management
  async function getState() {
    return new Promise(resolve => {
      chrome.runtime.sendMessage({ type: 'GET_STATE' }, response => {
        const defaults = {
          enabled: true,
          sensitivity: 1.5,
          volume: 1.0,
          cooldown: 1500,
          detectionMode: 'microphone',
          slapCount: 0,
          language: 'en'
        };
        const s = response || defaults;
        // Validate all values are within safe bounds
        s.sensitivity = Math.max(0.1, Math.min(5.0, Number(s.sensitivity) || defaults.sensitivity));
        s.volume = Math.max(0.0, Math.min(1.0, Number(s.volume) || defaults.volume));
        s.cooldown = Math.max(100, Math.min(5000, Number(s.cooldown) || defaults.cooldown));
        s.slapCount = Math.max(0, Math.floor(Number(s.slapCount) || 0));
        s.enabled = typeof s.enabled === 'boolean' ? s.enabled : defaults.enabled;
        s.detectionMode = ['motion', 'microphone'].includes(s.detectionMode) ? s.detectionMode : defaults.detectionMode;
        s.language = LANGUAGE_OPTIONS.some(x => x.code === s.language) ? s.language : 'en';
        resolve(s);
      });
    });
  }

  async function saveState(s) {
    return new Promise(resolve => {
      chrome.runtime.sendMessage({ type: 'SET_STATE', state: s }, () => {
        resolve();
      });
    });
  }

  checkForUpdates(false);
});
