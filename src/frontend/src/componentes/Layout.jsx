import { NavLink, Outlet } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { MENU } from '../menu';

export default function Layout() {
  const { usuario, tiene, logout } = useAuth();
  const inicial = usuario.nombre.split(' ').map(p => p[0]).join('').slice(0, 2);
  return (
    <div className="flex min-h-screen">
      <nav className="fixed flex h-screen w-[70px] flex-col bg-primary-dark text-white md:w-[260px]">
        <div className="border-b border-white/10 p-5 text-xl font-extrabold tracking-tight"><span className="hidden md:inline">Steps</span><span className="text-accent">.</span></div>
        <ul className="flex-1 py-2">
          {MENU.filter(m => tiene(m.f)).map(m => (
            <li key={m.f}>
              <NavLink to={m.ruta} end={m.ruta === '/'} className={({ isActive }) =>
                `flex items-center justify-center gap-3 px-4 py-3 text-sm font-medium transition-all duration-150 md:justify-start md:px-6 ${isActive ? 'border-l-[3px] border-accent bg-white/10 text-white' : 'text-white/70 hover:bg-white/10 hover:text-white'}`}>
                <span>{m.ico}</span><span className="hidden md:inline">{m.txt}</span>
              </NavLink>
            </li>))}
        </ul>
        <div className="hidden border-t border-white/10 p-4 text-sm md:block">
          <div className="font-semibold">{usuario.nombre}</div>
          <div className="text-xs font-bold text-accent">{usuario.roles.join(' · ')}</div>
        </div>
      </nav>
      <main className="ml-[70px] min-w-0 flex-1 p-4 md:ml-[260px] md:p-8">
        <header className="mb-6 flex items-center justify-between border-b border-borde pb-4">
          <h1 className="text-2xl font-extrabold tracking-tight">Panel de gestión</h1>
          <div className="flex items-center gap-3">
            <div className="tarjeta flex items-center gap-2 px-3 py-1.5 text-sm">
              <span className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-xs font-bold text-white">{inicial}</span>{usuario.nombre}
            </div>
            <button className="btn btn-ghost btn-sm" onClick={logout}>Salir</button>
          </div>
        </header>
        <Outlet />
      </main>
    </div>
  );
}
