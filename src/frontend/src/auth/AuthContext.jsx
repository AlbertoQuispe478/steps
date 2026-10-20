import { createContext, useContext, useState } from 'react';
import { api } from '../api';

const Ctx = createContext(null);
export const useAuth = () => useContext(Ctx);

export function AuthProvider({ children }) {
  const [sesion, setSesion] = useState(() => JSON.parse(localStorage.getItem('steps_sesion') || 'null'));

  // HU-01 · POST /api/auth/login
  async function login(username, password) {
    const datos = await api('/auth/login', { method: 'POST', body: { username, password } });
    localStorage.setItem('steps_sesion', JSON.stringify(datos));
    setSesion(datos);
  }
  function logout() { localStorage.removeItem('steps_sesion'); setSesion(null); }
  const tiene = (funcion) => !!sesion?.usuario.funciones.includes(funcion);

  return <Ctx.Provider value={{ sesion, usuario: sesion?.usuario, login, logout, tiene }}>{children}</Ctx.Provider>;
}
