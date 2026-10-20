import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext';
import { MENU } from '../../menu';

// Provisional: acceso rápido a lo permitido. Los KPIs reales llegan con HU-10 (vistas v_kpi_*).
export default function Dashboard() {
  const { usuario, tiene } = useAuth();
  return (
    <>
      <p className="mb-4 text-sm text-suave">Hola, {usuario.nombre}. Estas son tus secciones:</p>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {MENU.filter(m => m.f !== 'dashboard' && tiene(m.f)).map(m => (
          <Link key={m.f} to={m.ruta} className="tarjeta p-5 transition-all duration-150 hover:border-primary">
            <div className="text-2xl">{m.ico}</div><div className="mt-2 font-bold">{m.txt}</div><div className="text-xs text-suave">{m.hu}</div>
          </Link>))}
      </div>
    </>
  );
}
