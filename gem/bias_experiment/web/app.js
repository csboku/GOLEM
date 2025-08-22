document.addEventListener('DOMContentLoaded', function() {
    const stationSelector = document.getElementById('station-scenario-select');
    const methodSelector = document.getElementById('method-select');
    const modelSelector = document.getElementById('model-scenario-select');
    const DATA_CACHE = {}; // Global data cache

    const toTitleCase = str => str.replace(/_/g, ' ').replace(/\w\S*/g, txt => txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase());

    // Function to fetch data if not in cache
    async function loadJson(url) {
        if (!DATA_CACHE[url]) {
            console.log(`Fetching ${url}...`);
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error(`Failed to load ${url}: ${response.statusText}`);
            }
            // Handle non-standard JSON with "Infinity"
            const text = await response.text();
            const sanitizedText = text.replace(/Infinity/g, 'null');
            DATA_CACHE[url] = JSON.parse(sanitizedText);
            console.log(`Loaded ${url}`);
        }
        return DATA_CACHE[url];
    }

    function updateHeader(elementId, title, stats, score) {
        const header = document.querySelector(`#${elementId} .panel-header`);
        let scoreHtml = score ? `<br><span style="font-size: 0.9rem; color: #dc3545;">Avg. RMSE: ${score}</span>` : '';
        header.innerHTML = `<h2>${title} ${scoreHtml}</h2>
            <div style="font-size: 0.8rem; font-weight: normal; display: flex; justify-content: space-around; margin-top: 0.5rem;">
                <span>Mean: ${stats.mean}</span><span>Std Dev: ${stats.std_dev}</span><span>Exceed %: ${stats.exceedance_pct}</span>
            </div>`;
    }

    function plotSpatial(divId, data, locations, zmin, zmax, colorscale = 'Viridis') {
        const trace = {
            x: data.map(d => d.x), y: data.map(d => d.y), z: data.map(d => d.value),
            type: 'heatmap', colorscale, zmin, zmax, showscale: true, colorbar: { title: 'ppm', len: 0.6 }
        };
        const stationTrace = {
            x: Object.values(locations).map(l => l[0]), y: Object.values(locations).map(l => l[1]),
            mode: 'markers', type: 'scatter', marker: { color: 'white', size: 10, symbol: 'x', line: { width: 2, color: 'black' } }
        };
        Plotly.newPlot(divId, [trace, stationTrace], { margin: { t: 5, r: 5, b: 5, l: 5 }, autosize: true, showlegend: false }, {responsive: true});
    }
    
    function plotStationLocations(divId, locations) {
        const stationTrace = {
            x: Object.values(locations).map(l => l[0]), y: Object.values(locations).map(l => l[1]),
            mode: 'markers', type: 'scatter', marker: { color: 'black', size: 12, symbol: 'x' }
        };
        Plotly.newPlot(divId, [stationTrace], {
            margin: { t: 5, r: 5, b: 5, l: 5 }, autosize: true,
            xaxis: { range: [0, 90000], showgrid: false, zeroline: false, showticklabels: false },
            yaxis: { range: [0, 90000], showgrid: false, zeroline: false, showticklabels: false }
        }, {responsive: true});
    }

    function plotDistributions(originalPdf, correctedPdf, stationPdf, correctedName) {
        const traces = [
            { ...stationPdf, name: 'Stations (Observed)', type: 'scatter', mode: 'lines', line: { color: '#28a745', dash: 'dash', width: 2 } },
            { ...originalPdf, name: 'Original Model', type: 'scatter', mode: 'lines', line: { color: '#dc3545', width: 2 } },
            { ...correctedPdf, name: correctedName, type: 'scatter', mode: 'lines', line: { color: '#007bff', width: 4 } }
        ];
        Plotly.newPlot('dist-plot', traces, {
            legend: { x: 0.5, y: 1, xanchor: 'center', yanchor: 'bottom', orientation: 'h' },
            margin: { t: 40, r: 20, b: 40, l: 50 },
            xaxis: { title: 'Pollutant X (ppm)', range: [30, 90] },
            yaxis: { title: 'Density', showticklabels: false },
            shapes: [{ type: 'line', x0: 65, y0: 0, x1: 65, y1: 1, yref: 'paper', line: { color: 'black', width: 2, dash: 'dot' }}]
        }, {responsive: true});
    }

    async function updateDashboard() {
        const stationScn = stationSelector.value;
        const method = methodSelector.value;
        const modelScn = modelSelector.value;
        const titleMethod = toTitleCase(method);

        try {
            // Load all necessary data in parallel
            const dataPaths = {
                summary: `data/${stationScn}/summary.json`,
                scores: `data/${stationScn}/scores.json`,
                locations: `data/${stationScn}/station_locations.json`,
                ranges: `data/${stationScn}/global_ranges.json`,
                stationsPdf: `data/${stationScn}/stations_pdf.json`,
                origSpat: `data/${stationScn}/${modelScn}_original_spatial.json`,
                corrSpat: `data/${stationScn}/${modelScn}_${method}_spatial.json`,
                origPdf: `data/${stationScn}/${modelScn}_original_pdf.json`,
                corrPdf: `data/${stationScn}/${modelScn}_${method}_pdf.json`
            };

            const [
                summary, scores, locations, ranges, stationsPdf,
                origSpat, corrSpat, origPdf, corrPdf
            ] = await Promise.all(Object.values(dataPaths).map(loadJson));

            // Update headers
            updateHeader('station-panel', 'Stations (Observed)', summary[modelScn]['stations'], null);
            updateHeader('original-panel', 'Original Model', summary[modelScn]['original'], scores['Original']);
            updateHeader('corrected-panel', titleMethod, summary[modelScn][method], scores[titleMethod]);
            
            // Plot spatial maps
            plotStationLocations('station-plot', locations);
            plotSpatial('original-plot', origSpat, locations, 0, 80);
            plotSpatial('corrected-plot', corrSpat, locations, 0, 80);
            
            // Calculate and plot difference
            const diffData = origSpat.map((d, i) => ({ ...d, value: corrSpat[i].value - d.value }));
            plotSpatial('difference-plot', diffData, locations, -10, 10, 'RdBu');
            updateHeader('difference-panel', 'Correction Effect', { mean: (diffData.reduce((a, b) => a + b.value, 0) / diffData.length).toFixed(2), std_dev: 'N/A', exceedance_pct: 'N/A' }, null);
            
            // Plot distributions
            plotDistributions(origPdf, corrPdf, stationsPdf, titleMethod);

        } catch (error) {
            console.error("Failed to update dashboard:", error);
        }
    }

    async function initialize() {
        stationSelector.addEventListener('change', updateDashboard);
        methodSelector.addEventListener('change', updateDashboard);
        modelSelector.addEventListener('change', updateDashboard);
        await updateDashboard();
    }

    initialize();
});