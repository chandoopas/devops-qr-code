from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import qrcode
from azure.storage.blob import BlobServiceClient, ContentSettings
import os
from io import BytesIO
from dotenv import load_dotenv
import uuid

# Load environment variables
load_dotenv()

app = FastAPI()

# CORS middleware - allows frontend to call backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # Frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic model for request validation
class URLRequest(BaseModel):
    url: str

# Azure Blob Storage configuration
AZURE_CONNECTION_STRING = os.getenv('AZURE_STORAGE_CONNECTION_STRING')
AZURE_CONTAINER_NAME = os.getenv('AZURE_CONTAINER_NAME', 'qr-codes')
AZURE_STORAGE_ACCOUNT_NAME = os.getenv('AZURE_STORAGE_ACCOUNT_NAME')

# Initialize Azure Blob Service Client
try:
    blob_service_client = BlobServiceClient.from_connection_string(AZURE_CONNECTION_STRING)
    container_client = blob_service_client.get_container_client(AZURE_CONTAINER_NAME)
    print(f"✅ Connected to Azure Storage: {AZURE_STORAGE_ACCOUNT_NAME}")
except Exception as e:
    print(f"❌ Failed to connect to Azure Storage: {e}")

@app.get("/")
def read_root():
    return {
        "message": "QR Code Generator API with Azure Blob Storage",
        "status": "running",
        "storage": "Azure Blob Storage"
    }

@app.get("/health")
def health_check():
    """Health check endpoint"""
    try:
        # Test Azure connection
        container_client.get_container_properties()
        return {
            "status": "healthy",
            "azure_storage": "connected",
            "container": AZURE_CONTAINER_NAME
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e)
        }

@app.post("/generate")
async def generate_qr_code(request: URLRequest):
    """
    Generate QR code and upload to Azure Blob Storage
    
    Args:
        request: URLRequest containing the URL to encode
        
    Returns:
        JSON with QR code URL and metadata
    """
    try:
        print(f"📝 Generating QR code for: {request.url}")
        
        # Step 1: Generate QR code
        qr = qrcode.QRCode(
            version=1,  # Controls size (1 is smallest)
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(request.url)
        qr.make(fit=True)
        
        # Create QR code image
        img = qr.make_image(fill_color="black", back_color="white")
        print("✅ QR code image created")
        
        # Step 2: Convert image to bytes
        img_byte_arr = BytesIO()
        img.save(img_byte_arr, format='PNG')
        img_byte_arr.seek(0)
        print("✅ Image converted to bytes")
        
        # Step 3: Generate unique filename
        filename = f"qr_{uuid.uuid4().hex[:8]}.png"
        print(f"📁 Filename: {filename}")
        
        # Step 4: Upload to Azure Blob Storage
        blob_client = container_client.get_blob_client(filename)
        
        # Upload with content type
        blob_client.upload_blob(
            img_byte_arr,
            content_settings=ContentSettings(content_type='image/png'),
            overwrite=True
        )
        print("✅ Uploaded to Azure Blob Storage")
        
        # Step 5: Generate Azure Blob URL
        qr_code_url = f"https://{AZURE_STORAGE_ACCOUNT_NAME}.blob.core.windows.net/{AZURE_CONTAINER_NAME}/{filename}"
        
        print(f"🔗 QR Code URL: {qr_code_url}")
        
        return {
            "message": "QR code generated successfully",
            "qr_code_url": qr_code_url,
            "filename": filename,
            "original_url": request.url,
            "storage": "Azure Blob Storage"
        }
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to generate QR code: {str(e)}")

@app.delete("/delete/{filename}")
async def delete_qr_code(filename: str):
    """Delete a QR code from Azure Blob Storage"""
    try:
        blob_client = container_client.get_blob_client(filename)
        blob_client.delete_blob()
        
        return {
            "message": "QR code deleted successfully",
            "filename": filename
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/list")
async def list_qr_codes():
    """List all QR codes in Azure Blob Storage"""
    try:
        blobs = container_client.list_blobs()
        blob_list = []
        
        for blob in blobs:
            blob_url = f"https://{AZURE_STORAGE_ACCOUNT_NAME}.blob.core.windows.net/{AZURE_CONTAINER_NAME}/{blob.name}"
            blob_list.append({
                "name": blob.name,
                "url": blob_url,
                "size": blob.size,
                "created": blob.creation_time.isoformat() if blob.creation_time else None
            })
        
        return {
            "count": len(blob_list),
            "qr_codes": blob_list
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)