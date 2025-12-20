pragma Singleton
import QtQuick
import Quickshell.Io
import qs.config

QtObject {
    id: root

    // Current weather data
    property string weatherSymbol: ""
    property real currentTemp: 0
    property real maxTemp: 0
    property real minTemp: 0
    property int weatherCode: 0
    property real windSpeed: 0
    property bool dataAvailable: false

    // Sun position data
    property string sunrise: ""  // HH:MM format
    property string sunset: ""   // HH:MM format
    property real sunProgress: 0.0  // 0.0-1.0 position on the arc
    property bool isDay: true
    property string timeOfDay: "Day"  // "Day", "Evening", "Night"
    property string weatherDescription: ""

    // Debug mode
    property bool debugMode: false
    property real debugHour: 12.0  // 0-24 hour format (e.g., 14.5 = 2:30 PM)
    property int debugWeatherCode: 0

    // Debug sunrise/sunset (default: 6:00 and 18:00)
    readonly property real debugSunriseHour: 6.0
    readonly property real debugSunsetHour: 18.0

    // Calculate debug values based on debugHour
    readonly property real debugSunProgress: {
        if (debugHour >= debugSunriseHour && debugHour <= debugSunsetHour) {
            // Daytime: sun moves from 0 to 1
            return (debugHour - debugSunriseHour) / (debugSunsetHour - debugSunriseHour);
        } else {
            // Nighttime: moon moves from 0 to 1
            var nightDuration = 24 - (debugSunsetHour - debugSunriseHour);
            if (debugHour > debugSunsetHour) {
                return (debugHour - debugSunsetHour) / nightDuration;
            } else {
                return (debugHour + (24 - debugSunsetHour)) / nightDuration;
            }
        }
    }

    readonly property bool debugIsDay: debugHour >= debugSunriseHour && debugHour <= debugSunsetHour

    // Time periods with smooth transitions
    // 6-8: Evening (dawn), 8-18: Day, 18-20: Evening (dusk), 20-6: Night
    readonly property real debugDayAmount: {
        var h = debugHour;
        if (h >= 8 && h <= 18) return 1.0;  // Full day
        if (h > 6 && h < 8) return (h - 6) / 2;  // Dawn transition: 0 -> 1
        if (h > 18 && h < 20) return 1.0 - (h - 18) / 2;  // Dusk transition: 1 -> 0
        return 0.0;  // Night
    }

    readonly property real debugEveningAmount: {
        var h = debugHour;
        if (h >= 6 && h <= 8) return 1.0 - (h - 6) / 2;  // Dawn: 1 -> 0
        if (h >= 18 && h <= 20) return (h - 18) / 2 + (1.0 - (h - 18) / 2) * (h < 19 ? 1 : 0);  // Dusk
        if (h > 18 && h < 20) return 1.0 - Math.abs(h - 19);  // Peak at 19
        return 0.0;
    }

    readonly property real debugNightAmount: {
        var h = debugHour;
        if (h >= 20 || h <= 6) return 1.0;  // Full night
        if (h > 18 && h < 20) return (h - 18) / 2;  // Dusk transition: 0 -> 1
        if (h > 6 && h < 8) return 1.0 - (h - 6) / 2;  // Dawn transition: 1 -> 0
        return 0.0;  // Day
    }

    // Simplified: calculate blend factors for smooth transitions
    // Returns values 0-1 for day, evening, night that sum to 1
    function calculateTimeBlend(hour) {
        var day = 0, evening = 0, night = 0;
        
        if (hour >= 8 && hour <= 17) {
            // Pure day (8:00 - 17:00)
            day = 1.0;
        } else if (hour > 6 && hour < 8) {
            // Dawn transition (6:00 - 8:00): evening -> day
            var t = (hour - 6) / 2;
            evening = 1.0 - t;
            day = t;
        } else if (hour > 17 && hour < 18) {
            // Pre-dusk (17:00 - 18:00): day -> evening
            var t = hour - 17;
            day = 1.0 - t;
            evening = t;
        } else if (hour >= 18 && hour < 20) {
            // Dusk transition (18:00 - 20:00): evening -> night
            var t = (hour - 18) / 2;
            evening = 1.0 - t;
            night = t;
        } else if (hour >= 20 || hour < 5) {
            // Pure night (20:00 - 5:00)
            night = 1.0;
        } else if (hour >= 5 && hour <= 6) {
            // Pre-dawn (5:00 - 6:00): night -> evening
            var t = hour - 5;
            night = 1.0 - t;
            evening = t;
        }
        
        return { day: day, evening: evening, night: night };
    }

    readonly property var debugTimeBlend: calculateTimeBlend(debugHour)
    readonly property var realTimeBlend: {
        var now = new Date();
        return calculateTimeBlend(now.getHours() + now.getMinutes() / 60);
    }

    // Effective blend (use debug or real)
    readonly property var effectiveTimeBlend: debugMode ? debugTimeBlend : realTimeBlend

    // For backward compatibility
    readonly property string debugTimeOfDay: {
        var blend = debugTimeBlend;
        if (blend.day >= blend.evening && blend.day >= blend.night) return "Day";
        if (blend.evening >= blend.night) return "Evening";
        return "Night";
    }

    // Effective values (use debug values when debugMode is on)
    readonly property real effectiveSunProgress: debugMode ? debugSunProgress : sunProgress
    readonly property string effectiveTimeOfDay: debugMode ? debugTimeOfDay : timeOfDay
    readonly property bool effectiveIsDay: debugMode ? debugIsDay : isDay
    readonly property int effectiveWeatherCode: debugMode ? debugWeatherCode : weatherCode
    readonly property string effectiveWeatherSymbol: debugMode ? getWeatherCodeEmoji(debugWeatherCode) : weatherSymbol
    readonly property string effectiveWeatherDescription: debugMode ? getWeatherDescription(debugWeatherCode) : weatherDescription

    // Weather effect types based on code
    readonly property string effectiveWeatherEffect: getWeatherEffect(effectiveWeatherCode)
    readonly property real effectiveWeatherIntensity: getWeatherIntensity(effectiveWeatherCode)

    function getWeatherEffect(code) {
        if (code === 0 || code === 1) return "clear";
        if (code === 2 || code === 3) return "clouds";
        if (code === 45 || code === 48) return "fog";
        if (code >= 51 && code <= 57) return "drizzle";
        if (code >= 61 && code <= 67) return "rain";
        if (code >= 71 && code <= 77) return "snow";
        if (code >= 80 && code <= 82) return "rain";
        if (code >= 85 && code <= 86) return "snow";
        if (code === 95) return "thunderstorm";
        if (code >= 96 && code <= 99) return "thunderstorm";
        return "clear";
    }

    function getWeatherIntensity(code) {
        // Returns 0.0 - 1.0 intensity
        if (code === 0 || code === 1) return 0.0;
        if (code === 2) return 0.3;  // Partly cloudy
        if (code === 3) return 0.7;  // Overcast
        if (code === 45) return 0.5;  // Fog
        if (code === 48) return 0.7;  // Rime fog
        if (code === 51 || code === 56) return 0.3;  // Light drizzle
        if (code === 53) return 0.5;  // Moderate drizzle
        if (code === 55 || code === 57) return 0.7;  // Dense drizzle
        if (code === 61) return 0.4;  // Light rain
        if (code === 63 || code === 66) return 0.6;  // Moderate rain
        if (code === 65 || code === 67) return 0.9;  // Heavy rain
        if (code === 71) return 0.3;  // Light snow
        if (code === 73) return 0.5;  // Moderate snow
        if (code === 75 || code === 77) return 0.8;  // Heavy snow
        if (code === 80) return 0.5;  // Light showers
        if (code === 81) return 0.7;  // Moderate showers
        if (code === 82) return 1.0;  // Heavy showers
        if (code === 85) return 0.6;  // Light snow showers
        if (code === 86) return 0.9;  // Heavy snow showers
        if (code === 95) return 0.8;  // Thunderstorm
        if (code >= 96) return 1.0;  // Thunderstorm with hail
        return 0.0;
    }

    // Internal state
    property int retryCount: 0
    property int maxRetries: 5
    property string cachedLat: ""
    property string cachedLon: ""

    function getWeatherDescription(code) {
        if (code === 0) return "Clear sky";
        if (code === 1) return "Mainly clear";
        if (code === 2) return "Partly cloudy";
        if (code === 3) return "Overcast";
        if (code === 45) return "Foggy";
        if (code === 48) return "Rime fog";
        if (code >= 51 && code <= 53) return "Light drizzle";
        if (code === 55) return "Dense drizzle";
        if (code >= 56 && code <= 57) return "Freezing drizzle";
        if (code === 61) return "Light rain";
        if (code === 63) return "Moderate rain";
        if (code === 65) return "Heavy rain";
        if (code >= 66 && code <= 67) return "Freezing rain";
        if (code === 71) return "Light snow";
        if (code === 73) return "Moderate snow";
        if (code === 75) return "Heavy snow";
        if (code === 77) return "Snow grains";
        if (code >= 80 && code <= 81) return "Rain showers";
        if (code === 82) return "Heavy showers";
        if (code >= 85 && code <= 86) return "Snow showers";
        if (code === 95) return "Thunderstorm";
        if (code >= 96 && code <= 99) return "Thunderstorm with hail";
        return "Unknown";
    }

    function parseTime(timeStr) {
        // Parse "HH:MM" to minutes since midnight
        var parts = timeStr.split(":");
        return parseInt(parts[0]) * 60 + parseInt(parts[1]);
    }

    function calculateSunPosition() {
        var now = new Date();
        var currentMinutes = now.getHours() * 60 + now.getMinutes();

        if (!sunrise || !sunset) {
            root.isDay = (now.getHours() >= 6 && now.getHours() < 18);
            root.sunProgress = root.isDay ? 0.5 : 0.5;
            root.timeOfDay = root.isDay ? "Day" : "Night";
            return;
        }

        var sunriseMinutes = parseTime(sunrise);
        var sunsetMinutes = parseTime(sunset);
        
        // Define golden hour (roughly 1 hour before sunset)
        var goldenHourStart = sunsetMinutes - 60;
        // Define twilight end (roughly 1 hour after sunset)
        var twilightEnd = sunsetMinutes + 60;
        // Define dawn start (roughly 1 hour before sunrise)
        var dawnStart = sunriseMinutes - 60;

        if (currentMinutes >= sunriseMinutes && currentMinutes <= sunsetMinutes) {
            // Daytime: sun moves along the arc
            root.isDay = true;
            root.sunProgress = (currentMinutes - sunriseMinutes) / (sunsetMinutes - sunriseMinutes);
            
            if (currentMinutes >= goldenHourStart) {
                root.timeOfDay = "Evening";
            } else {
                root.timeOfDay = "Day";
            }
        } else {
            // Nighttime
            root.isDay = false;
            
            if (currentMinutes > sunsetMinutes) {
                // After sunset
                if (currentMinutes <= twilightEnd) {
                    root.timeOfDay = "Evening";
                } else {
                    root.timeOfDay = "Night";
                }
                // Moon rises at sunset, sets at sunrise (simplified)
                var nightDuration = (24 * 60 - sunsetMinutes) + sunriseMinutes;
                var nightElapsed = currentMinutes - sunsetMinutes;
                root.sunProgress = nightElapsed / nightDuration;
            } else {
                // Before sunrise
                if (currentMinutes >= dawnStart) {
                    root.timeOfDay = "Day";  // Dawn
                } else {
                    root.timeOfDay = "Night";
                }
                var nightDuration = (24 * 60 - sunsetMinutes) + sunriseMinutes;
                var nightElapsed = (24 * 60 - sunsetMinutes) + currentMinutes;
                root.sunProgress = nightElapsed / nightDuration;
            }
        }
    }

    function getWeatherCodeEmoji(code) {
        if (code === 0)
            return "☀️";
        if (code === 1)
            return "🌤️";
        if (code === 2)
            return "⛅";
        if (code === 3)
            return "☁️";
        if (code === 45)
            return "🌫️";
        if (code === 48)
            return "🌨️";
        if (code >= 51 && code <= 53)
            return "🌦️";
        if (code === 55)
            return "🌧️";
        if (code >= 56 && code <= 57)
            return "🧊";
        if (code >= 61 && code <= 65)
            return "🌧️";
        if (code >= 66 && code <= 67)
            return "🧊";
        if (code >= 71 && code <= 77)
            return "❄️";
        if (code >= 80 && code <= 81)
            return "🌦️";
        if (code === 82)
            return "🌧️";
        if (code >= 85 && code <= 86)
            return "🌨️";
        if (code === 95)
            return "⛈️";
        if (code >= 96 && code <= 99)
            return "🌩️";
        return "❓";
    }

    function convertTemp(temp) {
        if (Config.weather.unit === "F") {
            return (temp * 9 / 5) + 32;
        }
        return temp;
    }

    function fetchWeatherWithCoords(lat, lon) {
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current_weather=true&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset&timezone=auto";
        weatherProcess.command = ["curl", "-s", url];
        weatherProcess.running = true;
    }

    function urlEncode(str) {
        return str.replace(/%/g, "%25").replace(/ /g, "%20").replace(/!/g, "%21").replace(/"/g, "%22").replace(/#/g, "%23").replace(/\$/g, "%24").replace(/&/g, "%26").replace(/'/g, "%27").replace(/\(/g, "%28").replace(/\)/g, "%29").replace(/\*/g, "%2A").replace(/\+/g, "%2B").replace(/,/g, "%2C").replace(/\//g, "%2F").replace(/:/g, "%3A").replace(/;/g, "%3B").replace(/=/g, "%3D").replace(/\?/g, "%3F").replace(/@/g, "%40").replace(/\[/g, "%5B").replace(/]/g, "%5D");
    }

    function updateWeather() {
        var location = Config.weather.location.trim();
        if (location.length === 0) {
            geoipProcess.command = ["curl", "-s", "https://ipapi.co/json/"];
            geoipProcess.running = true;
            return;
        }

        var coords = location.split(",");
        var isCoordinates = coords.length === 2 && !isNaN(parseFloat(coords[0].trim())) && !isNaN(parseFloat(coords[1].trim()));

        if (isCoordinates) {
            cachedLat = coords[0].trim();
            cachedLon = coords[1].trim();
            fetchWeatherWithCoords(cachedLat, cachedLon);
        } else {
            var encodedCity = urlEncode(location);
            var geocodeUrl = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodedCity;
            geocodingProcess.command = ["curl", "-s", geocodeUrl];
            geocodingProcess.running = true;
        }
    }

    property Process geoipProcess: Process {
        running: false
        command: []

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var raw = text.trim();
                if (raw.length > 0) {
                    try {
                        var data = JSON.parse(raw);
                        if (data.latitude && data.longitude) {
                            root.cachedLat = data.latitude.toString();
                            root.cachedLon = data.longitude.toString();
                            root.fetchWeatherWithCoords(root.cachedLat, root.cachedLon);
                        } else {
                            root.dataAvailable = false;
                        }
                    } catch (e) {
                        root.dataAvailable = false;
                    }
                }
            }
        }

        onExited: function (code) {
            if (code !== 0) {
                root.dataAvailable = false;
            }
        }
    }

    property Process geocodingProcess: Process {
        running: false
        command: []

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var raw = text.trim();
                if (raw.length > 0) {
                    try {
                        var data = JSON.parse(raw);
                        if (data.results && data.results.length > 0) {
                            var result = data.results[0];
                            root.cachedLat = result.latitude.toString();
                            root.cachedLon = result.longitude.toString();
                            root.fetchWeatherWithCoords(root.cachedLat, root.cachedLon);
                        } else {
                            root.dataAvailable = false;
                        }
                    } catch (e) {
                        root.dataAvailable = false;
                    }
                }
            }
        }

        onExited: function (code) {
            if (code !== 0) {
                root.dataAvailable = false;
            }
        }
    }

    property Process weatherProcess: Process {
        running: false
        command: []

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var raw = text.trim();
                if (raw.length > 0) {
                    try {
                        var data = JSON.parse(raw);
                        if (data.current_weather && data.daily) {
                            var weather = data.current_weather;
                            var daily = data.daily;
                            
                            root.weatherCode = parseInt(weather.weathercode);
                            root.currentTemp = convertTemp(parseFloat(weather.temperature));
                            root.windSpeed = parseFloat(weather.windspeed);
                            
                            // Get today's max/min temps
                            if (daily.temperature_2m_max && daily.temperature_2m_max.length > 0) {
                                root.maxTemp = convertTemp(parseFloat(daily.temperature_2m_max[0]));
                            }
                            if (daily.temperature_2m_min && daily.temperature_2m_min.length > 0) {
                                root.minTemp = convertTemp(parseFloat(daily.temperature_2m_min[0]));
                            }

                            // Get sunrise/sunset times
                            if (daily.sunrise && daily.sunrise.length > 0) {
                                // Format: "2024-12-20T07:45" -> "07:45"
                                var sunriseStr = daily.sunrise[0];
                                root.sunrise = sunriseStr.split("T")[1];
                            }
                            if (daily.sunset && daily.sunset.length > 0) {
                                var sunsetStr = daily.sunset[0];
                                root.sunset = sunsetStr.split("T")[1];
                            }

                            root.weatherSymbol = getWeatherCodeEmoji(root.weatherCode);
                            root.weatherDescription = getWeatherDescription(root.weatherCode);
                            root.calculateSunPosition();
                            root.dataAvailable = true;
                            root.retryCount = 0;
                        } else {
                            root.dataAvailable = false;
                            if (root.retryCount < root.maxRetries) {
                                root.retryCount++;
                                retryTimer.interval = Math.min(600000, 5000 * Math.pow(2, root.retryCount - 1));
                                retryTimer.start();
                            }
                        }
                    } catch (e) {
                        console.warn("WeatherService: JSON parse error:", e);
                        root.dataAvailable = false;
                        if (root.retryCount < root.maxRetries) {
                            root.retryCount++;
                            retryTimer.interval = Math.min(600000, 5000 * Math.pow(2, root.retryCount - 1));
                            retryTimer.start();
                        }
                    }
                }
            }
        }

        onExited: function (code) {
            if (code !== 0) {
                root.dataAvailable = false;
                if (root.retryCount < root.maxRetries) {
                    root.retryCount++;
                    retryTimer.interval = Math.min(600000, 5000 * Math.pow(2, root.retryCount - 1));
                    retryTimer.start();
                }
            }
        }
    }

    property Timer retryTimer: Timer {
        repeat: false
        running: false
        onTriggered: root.updateWeather()
    }

    property Timer refreshTimer: Timer {
        // Periodic weather refresh (every 10 minutes)
        interval: 600000
        running: true
        repeat: true
        onTriggered: root.updateWeather()
    }

    property Timer sunPositionTimer: Timer {
        // Update sun position every minute
        interval: 60000
        running: root.dataAvailable
        repeat: true
        onTriggered: root.calculateSunPosition()
    }

    property Connections configConnections: Connections {
        target: Config.weather
        function onLocationChanged() {
            root.updateWeather();
        }
        function onUnitChanged() {
            root.updateWeather();
        }
    }

    Component.onCompleted: {
        updateWeather();
    }
}
