'use client'

import { useState } from 'react'

export default function Home() {
  const [url, setUrl] = useState('')
  const [qrCodeUrl, setQrCodeUrl] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const generateQRCode = async () => {
    // Reset previous states
    setError('')
    setQrCodeUrl('')

    // Validate input
    if (!url.trim()) {
      setError('Please enter a URL')
      return
    }

    setLoading(true)

    try {
      console.log('Generating QR code for:', url)
      
      // Call Next.js API route (which then calls backend)
      // This way the API call happens server-side where http://backend:8000 works
      const response = await fetch('/api/generate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ url })  // ✅ FIXED: was 'inputUrl', now 'url'
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      console.log('Response:', data)
      
      setQrCodeUrl(data.qr_code_url)
    } catch (err) {
      console.error('Error generating QR code:', err)
      setError('Failed to generate QR code. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const handleKeyPress = (e) => {
    if (e.key === 'Enter') {
      generateQRCode()
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            QR Code Generator
          </h1>
          <p className="text-lg text-gray-600">
            Generate QR codes for any URL with Azure Blob Storage
          </p>
        </div>

        {/* Main Card */}
        <div className="bg-white rounded-lg shadow-xl p-8">
          {/* Input Section */}
          <div className="mb-6">
            <label htmlFor="url" className="block text-sm font-medium text-gray-700 mb-2">
              Enter URL
            </label>
            <input
              id="url"
              type="text"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder="https://example.com"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent outline-none transition"
              disabled={loading}
            />
          </div>

          {/* Generate Button */}
          <button
            onClick={generateQRCode}
            disabled={loading}
            className={`w-full py-3 px-6 rounded-lg font-medium text-white transition ${
              loading
                ? 'bg-gray-400 cursor-not-allowed'
                : 'bg-indigo-600 hover:bg-indigo-700 active:bg-indigo-800'
            }`}
          >
            {loading ? (
              <span className="flex items-center justify-center">
                <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Generating...
              </span>
            ) : (
              'Generate QR Code'
            )}
          </button>

          {/* Error Message */}
          {error && (
            <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-red-800 text-sm">{error}</p>
            </div>
          )}

          {/* QR Code Display */}
          {qrCodeUrl && (
            <div className="mt-8 text-center">
              <div className="inline-block p-6 bg-white border-2 border-gray-200 rounded-lg shadow-md">
                <img
                  src={qrCodeUrl}
                  alt="Generated QR Code"
                  className="w-64 h-64 mx-auto"
                />
              </div>
              
              {/* Download Link */}
              <div className="mt-4">
                <a
                  href={qrCodeUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
                >
                  <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                  </svg>
                  Open QR Code
                </a>
              </div>

              {/* URL Info */}
              <div className="mt-4 p-3 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-600">
                  <span className="font-medium">Original URL:</span>
                  <br />
                  <span className="break-all">{url}</span>
                </p>
              </div>
            </div>
          )}
        </div>

        {/* Footer Info */}
        <div className="mt-8 text-center text-sm text-gray-600">
          <p>Powered by FastAPI + Next.js + Azure Blob Storage</p>
        </div>
      </div>
    </div>
  )
}