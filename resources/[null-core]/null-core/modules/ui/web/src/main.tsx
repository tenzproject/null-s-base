import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import AuthGate from './core/AuthGate'
import './index.css'

declare global {
  interface Window {
    NullBlur?: { start: (o?: Record<string, unknown>) => void; refresh: () => void; stop: () => void }
  }
}

if (window.NullBlur) {
  window.NullBlur.start()
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    {/* <AuthGate>
      <App />
    </AuthGate> */}
    <App />
  </React.StrictMode>,
)
