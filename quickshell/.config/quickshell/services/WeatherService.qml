// ============================================================
// HAVA DURUMU SERVİSİ (Singleton)
// wttr.in üzerinden hava durumu verilerini çeker
// ============================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    property string city: "Istanbul"
    property int temp: 0
    property string feelsLike: "0"
    property string humidity: "0"
    property string desc: "Yükleniyor..."
    property string icon: "weather-cloudy.svg" // default
    property string materialIcon: "cloud"
    
    // Yeni Eklenen Celestial Dashboard Verileri
    property string uvIndex: "0"
    property string windSpeed: "0"
    property string windDir: ""
    property string visibility: "0"
    property string rainChance: "0"
    property string dewPoint: "0"

    // Optimize Edilmiş (Önceden Hesaplanmış) UI Formatları
    property string tempFormatted: "0°"
    property string feelsLikeFormatted: "0°"
    property string dewPointFormatted: "Çiy: 0°"
    property string rainChanceFormatted: "%0"
    property string forecastMinMax: "Y: -° D: -°"

    property var forecast: []
    property string sunrise: "--:--"
    property string sunset: "--:--"
    property string sunrise24h: "--:--"
    property string sunset24h: "--:--"
    property string moonPhase: ""
    property string moonPhaseTR: ""
    property string moonPhaseImage: "dolunay.png"
    property string moonIllum: "0"

    // Dinamik Açıklamalar (Apple-Style)
    property string feelsLikeDesc: "Yükleniyor..."
    property string uvLevel: "Düşük"
    property string uvDesc: "Yükleniyor..."
    property string visibilityDesc: "Yükleniyor..."
    property string rainLevel: "Beklenmiyor"
    property string rainDesc: "Yükleniyor..."
    property string humidityDesc: "Yükleniyor..."
    property real longitude: 0

    // Güneş konumu (0.0: Doğuş, 1.0: Batış, veya gece ise 0.0/1.0 dışı)
    property real sunProgress: 0.5

    property bool isDay: true
    property real nightProgress: 0.0

    function parseWttrTime(timeStr, baseDate) {
        var d = baseDate ? new Date(baseDate.getTime()) : new Date();
        if (!timeStr || timeStr.indexOf(":") === -1) return d;
        var parts = timeStr.trim().split(" ");
        var timeParts = parts[0].split(":");
        var hours = parseInt(timeParts[0], 10);
        var minutes = parseInt(timeParts[1], 10);
        
        if (parts.length > 1) {
            var ampm = parts[1].toUpperCase();
            if (ampm === "PM" && hours < 12) hours += 12;
            if (ampm === "AM" && hours === 12) hours = 0;
        }
        
        d.setHours(hours, minutes, 0, 0);
        return d;
    }

    function formatTime24h(timeStr) {
        if (!timeStr) return "--:--";
        var parts = timeStr.trim().split(" ");
        if (parts.length < 2) return timeStr;
        var timeParts = parts[0].split(":");
        var hours = parseInt(timeParts[0], 10);
        var minutes = timeParts[1];
        var ampm = parts[1].toUpperCase();
        if (ampm === "PM" && hours < 12) hours += 12;
        if (ampm === "AM" && hours === 12) hours = 0;
        var hStr = hours < 10 ? "0" + hours : "" + hours;
        return hStr + ":" + minutes;
    }

    readonly property var _windDirs: {
        "N": "Kuzey", "NNE": "Kuzey Kuzeydoğu", "NE": "Kuzeydoğu", "ENE": "Doğu Kuzeydoğu",
        "E": "Doğu", "ESE": "Doğu Güneydoğu", "SE": "Güneydoğu", "SSE": "Güney Güneydoğu",
        "S": "Güney", "SSW": "Güney Güneybatı", "SW": "Güneybatı", "WSW": "Batı Güneybatı",
        "W": "Batı", "WNW": "Batı Kuzeybatı", "NW": "Kuzeybatı", "NNW": "Kuzey Kuzeybatı"
    }

    readonly property var _daysTR: ["Paz", "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt"]

    function translateWindDir(dir) {
        return _windDirs[dir.toUpperCase()] || dir;
    }

    function getDayName(dateStr) {
        var d = new Date(dateStr);
        if (isNaN(d.getTime())) return dateStr;
        return _daysTR[d.getDay()];
    }

    function getCityLocalTime() {
        var localNow = new Date();
        if (root.longitude === 0) return localNow;
        
        // UTC time'ı bul
        var utcMs = localNow.getTime() + (localNow.getTimezoneOffset() * 60000);
        // Boylamdan saat farkını tahmin et (Her 15 derece = 1 saat)
        var offsetHours = Math.round(root.longitude / 15);
        return new Date(utcMs + (offsetHours * 3600000));
    }

    function updateSunProgress() {
        var now = getCityLocalTime();
        var sunriseDate = parseWttrTime(root.sunrise, now);
        var sunsetDate = parseWttrTime(root.sunset, now);
        
        if (now >= sunriseDate && now <= sunsetDate) {
            root.isDay = true;
            root.sunProgress = (now - sunriseDate) / (sunsetDate - sunriseDate);
            root.nightProgress = 0.0;
        } else {
            root.isDay = false;
            root.sunProgress = 0.0;
            if (now < sunriseDate) {
                var yesterdaySunset = new Date(sunsetDate.getTime() - 24 * 60 * 60 * 1000);
                root.nightProgress = (now - yesterdaySunset) / (sunriseDate - yesterdaySunset);
            } else {
                var tomorrowSunrise = new Date(sunriseDate.getTime() + 24 * 60 * 60 * 1000);
                root.nightProgress = (now - sunsetDate) / (tomorrowSunrise - sunsetDate);
            }
        }
    }

    // Şehir dosyasını oku
    Process {
        id: readCityProc
        command: ["sh", "-c", "cat ~/.config/quickshell/weather_city.txt 2>/dev/null || echo 'Istanbul'"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() !== "") {
                    root.city = line.trim()
                }
            }
        }
        onExited: root.fetchWeather()
    }

    function changeCity() {
        AppState.citySearchOpen = !AppState.citySearchOpen
    }

    Process {
        id: saveCityProc
        running: false
        onExited: root.fetchWeather()
    }

    // O(1) Sözlükler (Performans için)
    readonly property var _materialIcons: {
        "113": "clear_day", "116": "partly_cloudy_day",
        "119": "cloud", "122": "cloud", "143": "fog", "248": "fog", "260": "fog",
        "176": "rainy", "263": "rainy", "266": "rainy", "293": "rainy", "296": "rainy", "299": "rainy", "302": "rainy", "305": "rainy", "308": "rainy",
        "179": "weather_snowy", "182": "weather_snowy", "185": "weather_snowy", "227": "weather_snowy", "230": "weather_snowy", "323": "weather_snowy", "326": "weather_snowy", "329": "weather_snowy", "332": "weather_snowy", "335": "weather_snowy", "338": "weather_snowy",
        "200": "thunderstorm", "386": "thunderstorm", "389": "thunderstorm", "392": "thunderstorm", "395": "thunderstorm",
        "311": "weather_mix", "314": "weather_mix", "317": "weather_mix", "350": "weather_mix", "374": "weather_mix", "377": "weather_mix",
        "353": "rainy", "356": "rainy", "359": "rainy", "362": "rainy", "365": "rainy", "368": "rainy", "371": "rainy"
    }

    readonly property var _svgIcons: {
        "113": "weather-sunny.svg", "116": "weather-partly-cloudy.svg",
        "119": "weather-cloudy.svg", "122": "weather-cloudy.svg", "143": "weather-fog.svg", "248": "weather-fog.svg", "260": "weather-fog.svg",
        "176": "weather-rainy.svg", "263": "weather-rainy.svg", "266": "weather-rainy.svg", "293": "weather-rainy.svg", "296": "weather-rainy.svg", "299": "weather-rainy.svg", "302": "weather-rainy.svg", "305": "weather-rainy.svg", "308": "weather-rainy.svg",
        "179": "weather-snowy.svg", "182": "weather-snowy.svg", "185": "weather-snowy.svg", "227": "weather-snowy.svg", "230": "weather-snowy.svg", "323": "weather-snowy.svg", "326": "weather-snowy.svg", "329": "weather-snowy.svg", "332": "weather-snowy.svg", "335": "weather-snowy.svg", "338": "weather-snowy.svg",
        "200": "weather-lightning.svg", "386": "weather-lightning.svg", "389": "weather-lightning.svg", "392": "weather-lightning.svg", "395": "weather-lightning.svg",
        "311": "weather-snowy-rainy.svg", "314": "weather-snowy-rainy.svg", "317": "weather-snowy-rainy.svg", "350": "weather-snowy-rainy.svg", "374": "weather-snowy-rainy.svg", "377": "weather-snowy-rainy.svg",
        "353": "weather-rainy.svg", "356": "weather-rainy.svg", "359": "weather-rainy.svg", "362": "weather-rainy.svg", "365": "weather-rainy.svg", "368": "weather-rainy.svg", "371": "weather-rainy.svg"
    }

    readonly property var _moonPhaseImages: {
        "new moon": "yeniay.png", "waxing crescent": "hilal.png", "first quarter": "ilkdordun.jpg", "waxing gibbous": "siskinaybuyuyen.png",
        "full moon": "dolunay.png", "waning gibbous": "siskinaykuculen.png", "last quarter": "sondordun.png", "waning crescent": "hilalkuculen.png"
    }

    readonly property var _moonPhaseTranslations: {
        "new moon": "Yeni Ay", "waxing crescent": "Büyüyen Hilal", "first quarter": "İlk Dördün", "waxing gibbous": "Büyüyen Şişkin Ay",
        "full moon": "Dolunay", "waning gibbous": "Küçülen Şişkin Ay", "last quarter": "Son Dördün", "waning crescent": "Küçülen Hilal"
    }

    function mapMaterialWeatherIcon(code) {
        return _materialIcons[String(code)] || "cloud";
    }

    function mapWeatherIcon(code) {
        return _svgIcons[String(code)] || "weather-cloudy.svg";
    }

    function mapMoonPhaseImage(phase) {
        return _moonPhaseImages[phase.toLowerCase().trim()] || "dolunay.png";
    }

    function translateMoonPhase(phase) {
        var p = phase.toLowerCase().trim();
        return _moonPhaseTranslations[p] || phase;
    }

    // JSON Çekici
    property string _jsonBuf: ""
    Process {
        id: fetchProc
        command: ["curl", "-s", "https://wttr.in/" + encodeURIComponent(root.city) + "?format=j1&lang=tr"]
        stdout: SplitParser {
            onRead: function(line) {
                root._jsonBuf += line + "\n"
            }
        }
        onExited: function(code) {
            if (code !== 0 || root._jsonBuf.trim() === "") {
                root.desc = "Bağlantı Hatası";
                root._jsonBuf = "";
                return;
            }
            try {
                var data = JSON.parse(root._jsonBuf);

                if (data.nearest_area && data.nearest_area.length > 0) {
                    var area = data.nearest_area[0];
                    if (area.longitude) {
                        root.longitude = parseFloat(area.longitude);
                    }
                }

                if (data.weather && data.weather.length > 0) {
                    var astro = data.weather[0].astronomy[0];
                    if (astro) {
                        root.sunrise = astro.sunrise || "--:--";
                        root.sunset = astro.sunset || "--:--";
                        root.sunrise24h = root.formatTime24h(root.sunrise);
                        root.sunset24h = root.formatTime24h(root.sunset);
                        root.moonPhase = data.weather[0].astronomy[0].moon_phase || "";
                        root.moonPhaseImage = root.mapMoonPhaseImage(root.moonPhase);
                        root.moonPhaseTR = root.translateMoonPhase(root.moonPhase);
                        root.moonIllum = data.weather[0].astronomy[0].moon_illumination || "";
                        
                        // Güneş ilerlemesini hesapla
                        root.updateSunProgress();
                    }
                }

                if (data.current_condition && data.current_condition.length > 0) {
                    var cur = data.current_condition[0];
                    root.temp = parseInt(cur.temp_C) || 0;
                    root.feelsLike = cur.FeelsLikeC || "0";
                    root.humidity = cur.humidity || "0";
                    
                    root.uvIndex = cur.uvIndex || "0";
                    root.windSpeed = cur.windspeedKmph || "0";
                    root.windDir = cur.winddir16Point || "";
                    root.visibility = cur.visibility || "0";
                    
                    var weatherCode = cur.weatherCode;
                    root.icon = root.mapWeatherIcon(weatherCode);
                    root.materialIcon = root.mapMaterialWeatherIcon(weatherCode);

                    // Optimize Edilmiş Değişkenler
                    root.tempFormatted = root.temp + "°";
                    root.feelsLikeFormatted = root.feelsLike + "°";

                    if (cur.lang_tr && cur.lang_tr.length > 0) {
                        root.desc = cur.lang_tr[0].value;
                    } else if (cur.weatherDesc && cur.weatherDesc.length > 0) {
                        root.desc = cur.weatherDesc[0].value;
                    }

                    // Dinamik Açıklamalar ve Çeviriler (Apple Style - Kısa)
                    var fDiff = parseInt(root.feelsLike) - root.temp;
                    if (fDiff < -2) root.feelsLikeDesc = "Rüzgar havayı serinletiyor.";
                    else if (fDiff > 2) root.feelsLikeDesc = "Nem daha sıcak hissettiriyor.";
                    else root.feelsLikeDesc = "Beklenen sıcaklıkla aynı.";

                    var h = parseInt(root.humidity);
                    if (h < 30) root.humidityDesc = "Kuru hava, nemlendirici sürün.";
                    else if (h <= 60) root.humidityDesc = "İdeal nem seviyesi.";
                    else if (h <= 80) root.humidityDesc = "Hava biraz bunaltıcı.";
                    else root.humidityDesc = "Aşırı nemli, çok bunaltıcı.";
                    
                    var u = parseInt(root.uvIndex);
                    if (u <= 2) { 
                        root.uvLevel = "Düşük"; 
                        root.uvDesc = "Dışarısı için güvenli."; 
                    } else if (u <= 5) { 
                        root.uvLevel = "Orta"; 
                        root.uvDesc = "Saat " + root.sunset24h + "'a kadar korunun."; 
                    } else if (u <= 7) { 
                        root.uvLevel = "Yüksek"; 
                        root.uvDesc = "Saat " + root.sunset24h + "'a kadar korunun."; 
                    } else if (u <= 10) { 
                        root.uvLevel = "Çok Yüksek"; 
                        root.uvDesc = "Saat " + root.sunset24h + "'a kadar korunun."; 
                    } else { 
                        root.uvLevel = "Aşırı"; 
                        root.uvDesc = "Saat " + root.sunset24h + "'a kadar korunun."; 
                    }

                    root.windDir = root.translateWindDir(cur.winddir16Point || "");

                    var v = parseInt(root.visibility);
                    if (v >= 10) root.visibilityDesc = "Görüş tamamen açık.";
                    else if (v >= 5) root.visibilityDesc = "Hafif puslu bir hava.";
                    else if (v >= 2) root.visibilityDesc = "Görüş mesafesi düşük.";
                    else root.visibilityDesc = "Yoğun sis, dikkatli olun.";
                }

                if (data.weather && data.weather.length > 0) {
                    var fc = [];

                    // Bugünün yağış ihtimali ve çiy noktası
                    if (data.weather[0].hourly && data.weather[0].hourly.length > 0) {
                        root.rainChance = data.weather[0].hourly[0].chanceofrain || "0";
                        root.rainChanceFormatted = "%" + root.rainChance;
                        root.dewPoint = data.weather[0].hourly[0].DewPointC || "0";
                        root.dewPointFormatted = "Çiy: " + root.dewPoint + "°";

                        var r = parseInt(root.rainChance);
                        if (r === 0) {
                            root.rainLevel = "Beklenmiyor";
                            root.rainDesc = "Yağış beklenmiyor.";
                        } else if (r <= 20) {
                            root.rainLevel = "Çok Düşük";
                            root.rainDesc = "Hafif yağış geçişleri.";
                        } else if (r <= 50) {
                            root.rainLevel = "Orta";
                            root.rainDesc = "Aralıklı yağış ihtimali.";
                        } else if (r <= 80) {
                            root.rainLevel = "Yüksek";
                            root.rainDesc = "Şemsiyenizi unutmayın.";
                        } else {
                            root.rainLevel = "Kesin";
                            root.rainDesc = "Kuvvetli yağış bekleniyor.";
                        }
                    }

                    // Precompute Forecast Strings
                    if (data.weather.length > 0) {
                        root.forecastMinMax = "Y: " + data.weather[0].maxtempC + "° D: " + data.weather[0].mintempC + "°";
                    }

                    for (var i = 0; i < Math.min(data.weather.length, 3); i++) {
                        var day = data.weather[i];
                        var dateStr = day.date; // 2023-08-01
                        var max = day.maxtempC;
                        var min = day.mintempC;
                        var dIcon = "weather-sunny.svg";
                        var mIcon = "clear_day";
                        if (day.hourly && day.hourly.length > 4) {
                            dIcon = root.mapWeatherIcon(day.hourly[4].weatherCode); // Öğlen saatleri
                            mIcon = root.mapMaterialWeatherIcon(day.hourly[4].weatherCode);
                        }
                        fc.push({ date: dateStr, max: max, min: min, icon: dIcon, materialIcon: mIcon });
                    }
                    root.forecast = fc;
                }
            } catch (e) {
                console.warn("Weather parse error:", e);
                root.desc = "Veri Hatası";
            }
            root._jsonBuf = "";
        }
    }

    function fetchWeather() {
        if (fetchProc.running) return;
        _jsonBuf = "";
        fetchProc.command = ["curl", "-s", "https://wttr.in/" + encodeURIComponent(root.city) + "?format=j1&lang=tr"];
        fetchProc.running = true;
    }

    // Her 15 dakikada bir güncelle
    Timer {
        interval: 900000
        running: true
        repeat: true
        onTriggered: root.fetchWeather()
    }

    // Güneş konumu animasyonu için her dakika güncelle
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.updateSunProgress()
    }
}
