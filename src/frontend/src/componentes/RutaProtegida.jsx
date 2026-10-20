import { Navigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

// Sin sesión -> /login. Con sesión pero sin la función -> /sin-permiso (mismo criterio que el backend).
export default function RutaProtegida({ funcion, children }) {
  const { usuario, tiene } = useAuth();
  if (!usuario) return <Navigate to="/login" replace />;
  if (funcion && !tiene(funcion)) return <Navigate to="/sin-permiso" state={{ funcion }} replace />;
  return children;
}
