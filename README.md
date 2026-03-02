## 🎯 Project Overview
Full-stack QR code generator deployed on Azure Kubernetes Service with automated CI/CD, Infrastructure as Code, and monitoring.
**Live Demo:** [http://20.22.157.60](http://20.22.157.60) (if still running)

## 📊 Architecture
**High-Level Architecture:**
![High-Level Architecture](Screenshots📷/High-Level%20Architecture.drawio.svg)

## 🛠️ Technologies Used
**Frontend:** Next.js, React, Tailwind CSS 
**Backend:** FastAPI, Python, qrcode, azure-storage-blob 
**Infrastructure:** Azure Kubernetes Service (AKS), Terraform 
**CI/CD:** GitHub Actions 
**Monitoring:** Prometheus, Grafana 
**Container Registry:** Azure Container Registry 
**Storage:** Azure Blob Storage

## ✨ Key Features
- ✅ Automated CI/CD pipeline (build, test, deploy) 
- ✅ Infrastructure as Code with Terraform 
- ✅ Kubernetes orchestration with high availability 
- ✅ Real-time monitoring with Prometheus & Grafana 
- ✅ Microservices architecture 
- ✅ Cloud-native design 
- ✅ Cost-optimized ($10/month with destroy strategy)

## 🚀 What I Learned
- Containerization with Docker 
- Kubernetes orchestration 
- Azure cloud services 
- CI/CD automation 
- Infrastructure as Code 
- Monitoring and observability 
- Cost optimization strategies

## 📈 Monitoring
20+ pre-built dashboards showing: 
- Real-time CPU/memory usage 
- Request rates and latencies 
- Pod health status 
- Historical trends

## 💰 Cost Management
Implemented cost optimization: 
- Terraform destroy strategy: ~$10/month 
- Resource limits and quotas 
- Auto-scaling disabled for predictable costs

## 📸 Screenshots

### Application UI 
![Application UI](Screenshots📷/Application%201.1.png)

### Grafana Dashboards 
![Kubernetes Cluster Overview Dashboard](Screenshots📷/Kubernetes%20Cluster%20Overview%20Dashboard.png)
![Node Exporter](Screenshots📷/Node%20Exporter.png)
![Your Application Pods Dashboard](Screenshots📷/Your%20Application%20Pods%20Dashboard.png)

### GitHub Actions Pipeline 
![CI:CD Workflow](Screenshots📷/CI:CD%20Workflow.png)

### Azure Portal Resources
![Container Registry](Screenshots📷/Container%20registires.png)
![AKS](Screenshots📷/AKS.png)