import http from 'k6/http';
import { check } from 'k6';

// Configuración: 50 usuarios concurrentes durante 30 segundos
export let options = {
  vus: 50,          // 50 usuarios virtuales simultáneos
  duration: '30s',  // tiempo total de la prueba
};

// ⚡ Login único antes de la prueba
let token;

export function setup() {
  let loginRes = http.post(
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyDpxY8-TjTrDaq_64zeLFfYdqn5HMek9fk',
    JSON.stringify({
      email: 'hpablobenja20@gmail.com',
      password: '123456789',
      returnSecureToken: true,
    }),
    { headers: { 'Content-Type': 'application/json' } }
  );

  check(loginRes, { 'login status 200': (r) => r.status === 200 });

  token = loginRes.json('idToken');
  return { token }; // se pasa al default()
}

// 🚀 Cada usuario hará peticiones GET con el mismo token
export default function (data) {
  let res = http.get(
    'https://firestore.googleapis.com/v1/projects/flutter-project-24297/databases/%28default%29/documents/courses',
    { headers: { Authorization: `Bearer ${data.token}` } }
  );

  check(res, { 'firestore status 200': (r) => r.status === 200 });
}
