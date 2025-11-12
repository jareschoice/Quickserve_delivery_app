// Auto-generated socket client for frontend
if (typeof window !== 'undefined') {
  if (!window.socket) {
    try {
      window.socket = (typeof io !== 'undefined') ? io('http://192.168.79.104:5555') : null;
    } catch (e) {
      window.socket = null;
    }
  }
}
export default window.socket;