import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './styles/index.css'

const devMode = !(window as any)?.['invokeNative']
const root = ReactDOM.createRoot(document.getElementById('root')!)

const renderApp = () => {
  root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>,
  )
}

if (devMode) {
  renderApp()
} else {
  // lb-phone sends componentsLoaded when the app iframe is ready
  if (window.name === '' || devMode) {
    window.addEventListener('message', (event) => {
      if (event.data === 'componentsLoaded') renderApp()
    })
  }
}
