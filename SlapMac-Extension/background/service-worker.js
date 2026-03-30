// SlapMac Extension - Background Service Worker
// Manages extension state and coordinates between popup and content

const DEFAULT_STATE = {
  enabled: true,
  sensitivity: 1.5,
  volume: 1.0,
  cooldown: 300,
  detectionMode: 'motion', // 'motion' | 'microphone'
  slapCount: 0
};

// Initialize state
chrome.runtime.onInstalled.addListener(async () => {
  const existing = await chrome.storage.local.get('slapMacState');
  if (!existing.slapMacState) {
    await chrome.storage.local.set({ slapMacState: DEFAULT_STATE });
  }
});

// Handle messages from popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'GET_STATE') {
    chrome.storage.local.get('slapMacState').then(result => {
      sendResponse(result.slapMacState || DEFAULT_STATE);
    });
    return true; // async response
  }

  if (message.type === 'SET_STATE') {
    chrome.storage.local.set({ slapMacState: message.state }).then(() => {
      sendResponse({ success: true });
    });
    return true;
  }

  if (message.type === 'INCREMENT_SLAP') {
    chrome.storage.local.get('slapMacState').then(result => {
      const state = result.slapMacState || DEFAULT_STATE;
      state.slapCount += 1;
      return chrome.storage.local.set({ slapMacState: state });
    }).then(() => {
      sendResponse({ success: true });
    });
    return true;
  }
});
