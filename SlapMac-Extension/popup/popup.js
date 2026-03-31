// SlapMac Extension - Popup Controller
document.addEventListener('DOMContentLoaded', async () => {
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
  const testSoundBtn = document.getElementById('test-sound');
  const showDonateBtn = document.getElementById('show-donate');
  const donateModal = document.getElementById('donate-modal');
  const closeDonateBtn = document.getElementById('close-donate');

  // State
  let state = await getState();
  let detector = null;

  // Initialize UI from state
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

  testSoundBtn.addEventListener('click', () => {
    playSound(state.volume);
    animateSlap();
  });

  showDonateBtn.addEventListener('click', () => {
    donateModal.style.display = 'flex';
  });

  closeDonateBtn.addEventListener('click', () => {
    donateModal.style.display = 'none';
  });

  donateModal.addEventListener('click', (e) => {
    if (e.target === donateModal) {
      donateModal.style.display = 'none';
    }
  });

  // Functions
  function updateUI(s) {
    toggleEnabled.checked = s.enabled;
    statusText.textContent = s.enabled ? 'Enabled' : 'Disabled';
    statusIndicator.className = 'status-indicator ' + (s.enabled ? 'listening' : 'disabled');
    statusLabel.textContent = s.enabled ? 'Listening for taps...' : 'Detection paused';
    slapCountEl.textContent = s.slapCount || 0;
    detectionMode.value = s.detectionMode || 'motion';
    sensitivitySlider.value = s.sensitivity;
    sensitivityValue.textContent = s.sensitivity.toFixed(1);
    volumeSlider.value = s.volume;
    volumeValue.textContent = Math.round(s.volume * 100) + '%';
    cooldownSlider.value = s.cooldown;
    cooldownValue.textContent = s.cooldown + 'ms';
  }

  function animateSlap() {
    const counter = document.querySelector('.counter-value');
    counter.style.transform = 'scale(1.3)';
    counter.style.transition = 'transform 0.15s';
    setTimeout(() => {
      counter.style.transform = 'scale(1)';
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
        statusLabel.textContent = 'Motion permission denied';
        statusIndicator.className = 'status-indicator disabled';
      });
    } else if (typeof DeviceMotionEvent !== 'undefined') {
      setupMotionListener(s);
    } else {
      statusLabel.textContent = 'Motion not available, try Microphone mode';
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

      statusLabel.textContent = '🎤 Listening via microphone...';
    }).catch(() => {
      statusLabel.textContent = 'Microphone permission denied';
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
          slapCount: 0
        };
        const s = response || defaults;
        // Validate all values are within safe bounds
        s.sensitivity = Math.max(0.1, Math.min(5.0, Number(s.sensitivity) || defaults.sensitivity));
        s.volume = Math.max(0.0, Math.min(1.0, Number(s.volume) || defaults.volume));
        s.cooldown = Math.max(100, Math.min(5000, Number(s.cooldown) || defaults.cooldown));
        s.slapCount = Math.max(0, Math.floor(Number(s.slapCount) || 0));
        s.enabled = typeof s.enabled === 'boolean' ? s.enabled : defaults.enabled;
        s.detectionMode = ['motion', 'microphone'].includes(s.detectionMode) ? s.detectionMode : defaults.detectionMode;
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
});
