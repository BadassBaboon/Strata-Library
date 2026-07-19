// Функция генерации псевдослучайного числа на основе координат ячейки
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float px = 1.0 / iResolution.y;

    // --- ПОЛУЧЕНИЕ ДАННЫХ ИЗ МУЗЫКАЛЬНОГО КАНАЛА iChannel0 ---
    // Читаем басы (низкие частоты) из первой строки текстуры звука (x = 0.0 .. 0.1)
    float bass = texture(iChannel0, vec2(0.05, 0.25)).x;
    // Читаем средние частоты (mid) для дополнительной динамики
    float mids = texture(iChannel0, vec2(0.4, 0.25)).x;
    
    // Создаем коэффициенты усиления на основе музыки
    float musicPulse = 1.0 + bass * 0.8; // Общая пульсация туннеля
    float neonGlow = 0.5 + bass * 3.5;    // Сила неонового свечения кубиков

    // Параметры сетки туннеля
    float numLines = 25.0;     
    float cycleDuration = 1.5; 
    float decayRate = 3.0;     

    // 1. Построение 3D-туннеля
    float tunnelRadius = 0.45;
    float dScreen = length(uv);
    
    // Музыка слегка раскачивает/пульсирует радиус туннеля в такт биту
    float zTunnel = (tunnelRadius * (1.0 + bass * 0.07)) / max(dScreen, 0.0001); 
    float angleTunnel = atan(uv.y, uv.x);

    // Координаты поверхности туннеля (полет вперед)
    vec3 p = vec3(uv * zTunnel, zTunnel - iTime * 0.8);
    float lat = p.z;      
    float lon = angleTunnel; 

    // Свечение горизонтальных колец
    float mappedLat = (lat / 3.14159 + 0.5) * numLines;
    float distH = abs(fract(mappedLat) - 0.5); 
    float fwH = fwidth(mappedLat) * 0.75; 
    float maskH = smoothstep(0.12 + fwH, 0.12 - fwH, distH) + exp(-distH * 15.0) * 0.8;

    // Свечение продольных линий
    float mappedLon = (lon / 3.14159 + 0.5) * numLines;
    float distV = abs(fract(mappedLon) - 0.5);
    float fwV = fwidth(mappedLon) * 0.75;
    float maskV = smoothstep(0.12 + fwV, 0.12 - fwV, distV) + exp(-distV * 15.0) * 0.8;

    // --- РЕАКТИВНЫЕ НЕОНОВЫЕ КУБИКИ С АУДИОАНИМАЦИЕЙ ---
    vec2 cellId = floor(vec2(mappedLat, mappedLon));
    float randValue = hash(cellId);
    
    // Скорость мигания зависит от общей энергии музыки
    float boxTime = iTime * (1.0 + randValue * 1.5) + randValue * 10.0 + bass * 2.0;
    float boxIntensity = smoothstep(0.1, 0.5, sin(boxTime)) * smoothstep(0.9, 0.5, sin(boxTime));
    
    // Рисуем кубик
    vec2 localCoord = fract(vec2(mappedLat, mappedLon)) - 0.5;
    float boxSize = 0.35; 
    
    // Мягкая маска для создания эффекта неонового размытия по краям кубика
    float distToBoxEdge = max(abs(localCoord.x), abs(localCoord.y));
    float boxMask = smoothstep(boxSize, boxSize - 0.08, distToBoxEdge);
    
    // Внутреннее сплошное ядро кубика
    float boxCore = smoothstep(boxSize - 0.12, boxSize - 0.15, distToBoxEdge);
    
    // Порог появления: в моменты сильного баса вспыхивает больше кубиков (до 25% сетки)
    float spawnThreshold = 0.10 + bass * 0.15; 
    
    // Финальная маска кубика: ядро + внешнее неоновое свечение, умноженное на басы
    float activeBox = step(randValue, spawnThreshold) * boxIntensity;
    float finalBoxGlow = activeBox * (boxCore + boxMask * neonGlow);
    // ----------------------------------------------------

    // Пути для бегущих световых волн
    float prog0 = fract(p.z * 0.15);       
    float prog1 = 1.0 - fract(p.z * 0.15); 
    float prog2 = angleTunnel / 6.28318 + 0.5; 
    float prog3 = 1.0 - prog2;                 

    // Расчет времени для анимации импульсов
    float tGlobal = iTime / cycleDuration;
    
    float age0 = fract((tGlobal - 0.0) / 4.0 - prog0 * 0.25) * 4.0;
    float age1 = fract((tGlobal - 1.0) / 4.0 - prog1 * 0.25) * 4.0;
    float age2 = fract((tGlobal - 2.0) / 4.0 - prog2 * 0.25) * 4.0;
    float age3 = fract((tGlobal - 3.0) / 4.0 - prog3 * 0.25) * 4.0;

    float i0 = exp(-age0 * decayRate) + smoothstep(0.06, 0.0, age0) * 4.0;
    float i1 = exp(-age1 * decayRate) + smoothstep(0.06, 0.0, age1) * 4.0;
    float i2 = exp(-age2 * decayRate) + smoothstep(0.06, 0.0, age2) * 4.0;
    float i3 = exp(-age3 * decayRate) + smoothstep(0.06, 0.0, age3) * 4.0;

    // Цвета линий
    float tX = sin(angleTunnel) * 0.5 + 0.5;
    vec3 colH = mix(vec3(1.0, 0.0, 0.2), vec3(0.0, 0.3, 1.0), smoothstep(0.0, 0.5, tX));
    colH = mix(colH, vec3(0.0, 1.0, 0.2), smoothstep(0.5, 1.0, tX));

    float tY = fract(p.z * 0.2);
    vec3 colV = mix(vec3(1.0, 0.0, 0.2), vec3(0.0, 0.3, 1.0), smoothstep(0.0, 0.5, tY));
    colV = mix(colV, vec3(0.0, 1.0, 0.2), smoothstep(0.5, 1.0, tY));

    // Смешиваем базовые линии (их яркость тоже слегка подпитывается музыкой)
    vec3 finalColor = (((i0 + i1) * maskH * colH) + ((i2 + i3) * maskV * colV)) * (0.8 + bass * 0.4);
    
    // Добавляем неоновые кубики: у них яркий ядовитый цвет, который переходит в белый в самом центре
    vec3 neonColor = mix(colH, colV, 0.5) * 1.5 + vec3(0.2, 0.5, 1.0);
    finalColor += finalBoxGlow * neonColor;

    // Туман глубины
    float fog = smoothstep(0.0, 8.0, zTunnel);
    finalColor *= fog;

    // Свечение центра реагирует на средние частоты (эффект приближения источника звука)
    float centerGlow = exp(-dScreen * 3.0);
    finalColor += vec3(0.1, 0.4, 0.8) * centerGlow * (0.3 + mids * 0.6);

    float edgeGlow = smoothstep(0.0, 0.8, dScreen) * 0.1;
    finalColor += vec3(0.05, 0.1, 0.3) * edgeGlow * musicPulse;

    fragColor = vec4(finalColor, 1.0);
}
