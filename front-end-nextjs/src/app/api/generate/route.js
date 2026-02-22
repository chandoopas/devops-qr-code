export async function POST(request) {
  const body = await request.json();
  
  // This runs on server, can access backend service
  const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'http://backend:8000';
  
  const response = await fetch(`${backendUrl}/generate`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  
  const data = await response.json();
  return Response.json(data);
}