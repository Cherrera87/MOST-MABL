function MO_marina_interactivo
%% MOST – Capa límite marina (apoyo didáctico)
% Torre fija (z=10 m por defecto)
% "Indicadores" de forzamiento: azul (u_*) horizontal y rojo (H) vertical
% Banda "CASI NEUTRO" basada en |z/L| <= zeta0 (depende de u_*^3)
% Sombreado: INESTABLE (arriba de banda) y ESTABLE (abajo de banda)

clc; close all

%% Constantes
kappa  = 0.40;
g      = 9.81;
rho    = 1.22;
cp     = 1004;
theta0 = 290;   % K

% Umbral de casi neutro
zeta0 = 0.10;   % |z/L| <= 0.10

%% Figura
f = figure('Name','Monin–Obukhov (Marino)', ...
    'Units','centimeters','Position',[5 5 24 16], 'Color','w');

%% ====== CONTROLES ======
% u*
uicontrol(f,'Style','text','Units','normalized', ...
    'Position',[0.05 0.83 0.25 0.05], ...
    'String','u_* (momento, m s^{-1})','FontSize',10);

s_u = uicontrol(f,'Style','slider','Units','normalized', ...
    'Min',0.05,'Max',0.8,'Value',0.30, ...
    'Position',[0.05 0.78 0.25 0.05], ...
    'Callback',@update);

% H
uicontrol(f,'Style','text','Units','normalized', ...
    'Position',[0.05 0.70 0.25 0.05], ...
    'String','H (flujo de calor, W m^{-2})','FontSize',10);

s_H = uicontrol(f,'Style','slider','Units','normalized', ...
    'Min',-200,'Max',200,'Value',50, ...
    'Position',[0.05 0.65 0.25 0.05], ...
    'Callback',@update);

% z
uicontrol(f,'Style','text','Units','normalized', ...
    'Position',[0.05 0.57 0.25 0.05], ...
    'String','z (m)','FontSize',10);

e_z = uicontrol(f,'Style','edit','Units','normalized', ...
    'String','10','Position',[0.05 0.52 0.25 0.05], ...
    'Callback',@update);

%% ====== TEXTO RESULTADOS ======
txt = annotation(f,'textbox', ...
    'Units','normalized', ...
    'Position',[0.05 0.10 0.25 0.38], ...
    'Interpreter','latex', ...
    'FontSize',11, ...
    'HorizontalAlignment','left', ...
    'VerticalAlignment','top', ...
    'EdgeColor','none');

%% ====== EJE CONCEPTUAL (u_* y H) ======
ax = axes('Parent',f,'Position',[0.38 0.12 0.57 0.82]);
box on; grid on
xlabel('$u_*$ [$\mathrm{m\,s^{-1}}$]','Interpreter','latex','FontSize',12);
ylabel('H [$\mathrm{W\,m^{-2}}$]','Interpreter','latex','FontSize',12)
title('\bf Capa l\''imite marina: estabilidad (z/L) y forzamientos','Interpreter','latex','FontSize',12)
hold(ax,'on')
ax.TickLabelInterpreter = 'latex';

% Límites en unidades reales
uMin = s_u.Min; uMax = s_u.Max;
HMin = s_H.Min; HMax = s_H.Max;
xlim([uMin uMax]); ylim([HMin HMax]);

% Línea H=0 (referencia)
plot([uMin uMax],[0 0],'k-','LineWidth',1.2)

% Malla u_* para curvas/bandas
uLine = linspace(uMin,uMax,300);

% Inicialización con z=10 para arrancar (se actualiza en update)
z0  = str2double(e_z.String); if isnan(z0) || z0<=0, z0 = 10; end
HN0 = (rho*cp*theta0/(kappa*g))*(zeta0/z0) .* (uLine.^3);
HN0 = min(HN0, HMax);

% ----- Sombreado regímenes (según umbral |z/L|<=zeta0) -----
unstable_fill = patch([uLine fliplr(uLine)], [HN0 fliplr(HMax*ones(size(uLine)))], ...
    [1 0.85 0.80], 'EdgeColor','none','FaceAlpha',0.35);

stable_fill = patch([uLine fliplr(uLine)], [HMin*ones(size(uLine)) fliplr(-HN0)], ...
    [0.82 0.92 0.92], 'EdgeColor','none','FaceAlpha',0.35);

neutral_band = patch([uLine fliplr(uLine)], [HN0 -fliplr(HN0)], ...
    [0.75 0.85 1], 'EdgeColor','none','FaceAlpha',0.25);

neutral_top = plot(uLine,  HN0,'k--','LineWidth',0.5);
neutral_bot = plot(uLine, -HN0,'k--','LineWidth',0.5);

neutral_lbl = text(uMin + 0.65*(uMax-uMin), 0.60*HMax, ...
    sprintf('CASI NEUTRO: |z/L| <= %.2f', zeta0), ...
    'FontSize',10,'FontWeight','bold','Color',[0 0.25 0.7],'Interpreter','latex');

% Punto indicador del estado (u_*,H)
p_state = plot(s_u.Value, s_H.Value, 'ko','MarkerSize',8,'MarkerFaceColor','k');

% ---- Indicadores en ejes (con plot) ----
% Base para indicadores (a la izquierda, para no tapar el punto)
x0 = uMin + 0.05*(uMax-uMin);
y0 = 0;

% Línea horizontal que "marca" u_* (hasta u_* actual)
q_mom  = plot([x0 s_u.Value], [y0 y0], 'LineWidth',2,'Color','b');

% Línea vertical que "marca" H (hasta H actual)
q_heat = plot([x0 x0], [y0 s_H.Value], 'LineWidth',2,'Color','r');

% ---- Cabezas triangulares (patch) ----
% Tamaño base de la cabeza en unidades del eje
headLx = 0.02*(uMax-uMin);      % largo (x) de cabeza horizontal
headWy = 0.03*(HMax-HMin);      % ancho (y) de cabeza horizontal

headLy = 0.03*(HMax-HMin);      % largo (y) de cabeza vertical
headWx = 0.02*(uMax-uMin);      % ancho (x) de cabeza vertical

% Inicializa con triángulos "degenerados" (se actualizan en update)
mom_head  = patch([x0 x0 x0], [y0 y0 y0], 'b', 'EdgeColor','none', 'FaceAlpha',0.95);
heat_head = patch([x0 x0 x0], [y0 y0 y0], 'r', 'EdgeColor','none', 'FaceAlpha',0.95);


% Etiquetas (en unidades de los ejes)
t_u  = text(x0,y0,'', 'FontSize',10, 'Color','b', 'FontWeight','bold','Interpreter','latex');
t_H  = text(x0,y0,'', 'FontSize',10, 'Color','r', 'FontWeight','bold','Interpreter','latex');

ax.Layer='top';
ax.LineWidth=1.5;
ax.TickDir ='both';
%% Inicializar
update()

%% ====== FUNCIÓN UPDATE ======
    function update(~,~)
        ustar = s_u.Value;
        H     = s_H.Value;
        z     = str2double(e_z.String);

        if isnan(z) || z<=0
            z = 10;
            e_z.String = '10';
        end

        % L y z/L (MOST)
        if H == 0
            L = Inf;
            zeta = 0;
        else
            L = -(rho*cp*theta0*ustar^3)/(kappa*g*H);
            zeta = z/L;
        end

        % Régimen por z/L (umbral zeta0)
        if abs(zeta) <= zeta0
            reg = 'CASI NEUTRO';
        elseif zeta < -zeta0
            reg = 'INESTABLE';
        else
            reg = 'ESTABLE';
        end

tau = rho*ustar^2;

tau = rho*ustar^2;

tau = rho*ustar^2;

txt.String = { ...
    '\textbf{Inputs (ejes)}'
    ['$u_* = ' num2str(ustar,'%.2f') '\,\mathrm{m\,s^{-1}}$']
    ['$H = '  num2str(H,'%.1f')     '\,\mathrm{W\,m^{-2}}$']
    ' '
    '\textbf{MOST}'
    ['$\tau = \rho u_*^2 = ' num2str(tau,'%.3f') '\,\mathrm{kg\,m^{-1}\,s^{-2}}$']
    ['$L = '   num2str(L,'%.1f')    '\,\mathrm{m}$']
    ['$z/L = ' num2str(zeta,'%.2f') ' \; (z=' num2str(z,'%.1f') '\,\mathrm{m})$']
    ' '
    '\textbf{R\''EGIMEN:}'
    ['\textbf{' reg '}']
};




        % Punto del estado
        set(p_state,'XData',ustar,'YData',H);

        % -------- Actualizar banda casi neutra (depende de z) --------
        HN = (rho*cp*theta0/(kappa*g))*(zeta0/z) .* (uLine.^3);
        HN = min(HN, HMax);

        set(unstable_fill, 'XData',[uLine fliplr(uLine)], ...
            'YData',[HN fliplr(HMax*ones(size(uLine)))]);

        set(stable_fill, 'XData',[uLine fliplr(uLine)], ...
            'YData',[HMin*ones(size(uLine)) fliplr(-HN)]);

        set(neutral_band, 'XData',[uLine fliplr(uLine)], ...
            'YData',[HN -fliplr(HN)]);
        set(neutral_top,  'YData', HN);
        set(neutral_bot,  'YData',-HN);

        % -------- Indicadores en ejes (u_* y H) --------
        % Horizontal (u_*) desde x0 hasta u_* (NO proporcional: literal)
        set(q_mom,  'XData',[x0 ustar], 'YData',[y0 y0]);

        % Vertical (H) desde y0 hasta H (literal, con signo)
        set(q_heat, 'XData',[x0 x0],    'YData',[y0 H]);

        % -------- Cabeza triangular para u_* (apunta a la derecha) --------
% Punta en (ustar,0), base un poco a la izquierda
x_tip = ustar;
y_tip = y0;

x_base = x_tip - headLx;
y1 = y_tip - headWy/2;
y2 = y_tip + headWy/2;

% Si ustar está muy cerca de x0, evita que la cabeza se invierta
if x_base < x0
    x_base = (x0 + x_tip)/2;
end

set(mom_head,'XData',[x_tip x_base x_base], 'YData',[y_tip y1 y2]);

% -------- Cabeza triangular para H (apunta arriba o abajo según signo) --------
x_tip = x0;
y_tip = H;

% Si H=0, "esconde" la cabeza (triángulo degenerado)
if H == 0
    set(heat_head,'XData',[x0 x0 x0], 'YData',[y0 y0 y0]);
else
    sgn = sign(H);  % +1 arriba, -1 abajo
    y_base = y_tip - sgn*headLy;   % base opuesta al sentido
    x1 = x_tip - headWx/2;
    x2 = x_tip + headWx/2;

    set(heat_head,'XData',[x_tip x1 x2], 'YData',[y_tip y_base y_base]);
end


        % Etiquetas en unidades de los ejes
        xpad = 0.01*(uMax-uMin);
        ypad = 0.03*(HMax-HMin);

        set(t_u, ...
            'Interpreter','latex', ...
            'Position',[ustar + xpad, y0 + ypad], ...
            'String',sprintf('$u_* = %.2f\\,\\mathrm{m\\,s^{-1}}$', ustar));


        if H == 0
            set(t_H, ...
                'Interpreter','latex', ...
                'Position',[x0 + xpad, y0 + ypad], ...
                'String','$H = 0\\,\\mathrm{W\\,m^{-2}}$');
        else
            set(t_H, ...
                'Interpreter','latex', ...
                'Position',[x0 + xpad, H + sign(H)*ypad], ...
                'String',sprintf('$H = %.0f\\,\\mathrm{W\\,m^{-2}}$', H));
        end

    end
end
