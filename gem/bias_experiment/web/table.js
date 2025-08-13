document.addEventListener('DOMContentLoaded', function() {
    const stationSelector = document.getElementById('station-scenario-select');
    const tableContainer = document.getElementById('table-container');
    const DATA_CACHE = {};

    async function loadJson(url) {
        if (!DATA_CACHE[url]) {
            const response = await fetch(url);
            if (!response.ok) throw new Error(`Failed to load ${url}`);
            const text = await response.text();
            DATA_CACHE[url] = JSON.parse(text.replace(/Infinity/g, 'null'));
        }
        return DATA_CACHE[url];
    }

    function createTable(title, headers, data) {
        const table = document.createElement('table');
        const thead = table.createTHead();
        const tbody = table.createTBody();
        
        let titleRow = thead.insertRow();
        let titleCell = titleRow.insertCell();
        titleCell.colSpan = headers.length;
        titleCell.innerHTML = `<h2>${title}</h2>`;
        titleCell.style.textAlign = 'center';

        let headerRow = thead.insertRow();
        headers.forEach(text => {
            let th = document.createElement('th');
            th.textContent = text;
            headerRow.appendChild(th);
        });

        data.forEach(rowData => {
            let row = tbody.insertRow();
            rowData.forEach(cellData => {
                let cell = row.insertCell();
                cell.textContent = cellData;
            });
        });
        
        return table;
    }

    async function updateTables() {
        const stationScn = stationSelector.value;
        tableContainer.innerHTML = 'Loading...';

        try {
            const summary = await loadJson(`data/${stationScn}/summary.json`);
            const scores = await loadJson(`data/${stationScn}/scores.json`);

            tableContainer.innerHTML = ''; // Clear loading message

            // Summary Table
            const summaryHeaders = ["Scenario", "Metric", "Stations", "Original", "ML", "Variance", "QM", "Spatial Delta", "Delta", "Scaling", "Parametric", "Parametric Gamma"];
            const summaryData = [];
            for (const modelScn in summary) {
                const metrics = Object.keys(summary[modelScn].stations);
                metrics.forEach(metric => {
                    const row = [modelScn, metric];
                    summaryHeaders.slice(2).forEach(method => {
                        const methodName = method.toLowerCase().replace(' ', '_');
                        row.push(summary[modelScn][methodName] ? summary[modelScn][methodName][metric] : 'N/A');
                    });
                    summaryData.push(row);
                });
            }
            tableContainer.appendChild(createTable('Summary Statistics', summaryHeaders, summaryData));

            // Scores Table
            const scoresHeaders = ["Method", "Avg. RMSE"];
            const scoresData = Object.entries(scores).map(([key, value]) => [key, value]);
            tableContainer.appendChild(createTable('RMSE Scores', scoresHeaders, scoresData));

        } catch (error) {
            tableContainer.innerHTML = `<p style="color: red;">Error loading data: ${error.message}</p>`;
            console.error(error);
        }
    }

    stationSelector.addEventListener('change', updateTables);
    updateTables();
});
