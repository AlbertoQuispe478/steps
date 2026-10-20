import { createRoot } from 'react-dom/client';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import './index.css';
import { AuthProvider } from './auth/AuthContext';
import RutaProtegida from './componentes/RutaProtegida';
import Layout from './componentes/Layout';
import Login from './paginas/auth/Login';
import Dashboard from './paginas/dashboard/Dashboard';
import Pendiente from './paginas/Pendiente';
import Clientes from './paginas/clientes/Clientes';
import SinPermiso from './paginas/SinPermiso';
import { MENU } from './menu';

// Pantallas ya construidas; el resto muestra el marcador "Pendiente".
const PAGINAS = { clientes: <Clientes /> };

createRoot(document.getElementById('root')).render(
  <BrowserRouter>
    <AuthProvider>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route element={<RutaProtegida><Layout /></RutaProtegida>}>
          <Route path="/" element={<Dashboard />} />
          {MENU.filter(m => m.ruta !== '/').map(m => (
            <Route key={m.f} path={m.ruta} element={<RutaProtegida funcion={m.f}>{PAGINAS[m.f] ?? <Pendiente titulo={m.txt} hu={m.hu} />}</RutaProtegida>} />))}
          <Route path="/sin-permiso" element={<SinPermiso />} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </AuthProvider>
  </BrowserRouter>
);
