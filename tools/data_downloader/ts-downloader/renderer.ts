import axios from 'axios';
import * as cheerio from 'cheerio';
import { URL } from 'url';

declare global {
    interface Window {
        electronAPI: {
            downloadFile: (url: string, filename: string) => void;
        };
    }
}

const urlInput = document.getElementById('url-input') as HTMLInputElement;
const fetchButton = document.getElementById('fetch-button') as HTMLButtonElement;
const filterInput = document.getElementById('filter-input') as HTMLInputElement;
const linkList = document.getElementById('link-list') as HTMLSelectElement;
const downloadSelectedButton = document.getElementById('download-selected-button') as HTMLButtonElement;
const downloadAllButton = document.getElementById('download-all-button') as HTMLButtonElement;
const status = document.getElementById('status') as HTMLDivElement;

let allLinks: string[] = [];

fetchButton.addEventListener('click', async () => {
    const url = urlInput.value;
    if (!url) {
        status.textContent = 'Please enter a URL.';
        return;
    }

    status.textContent = `Fetching links from ${url}...`;
    try {
        const response = await axios.get(url);
        const $ = cheerio.load(response.data);
        allLinks = [];
        $('a').each((i, el) => {
            const href = $(el).attr('href');
            if (href) {
                try {
                    const absoluteUrl = new URL(href, url).toString();
                    allLinks.push(absoluteUrl);
                } catch (error) {
                    console.error(`Invalid URL: ${href}`);
                }
            }
        });
        updateLinkList();
        status.textContent = `Found ${allLinks.length} links.`;
    } catch (error) {
        status.textContent = `Error fetching links: ${error.message}`;
    }
});

filterInput.addEventListener('input', () => {
    updateLinkList();
});

function updateLinkList() {
    const filterText = filterInput.value.toLowerCase();
    linkList.innerHTML = '';
    const filteredLinks = allLinks.filter(link => link.toLowerCase().includes(filterText));
    filteredLinks.forEach(link => {
        const option = document.createElement('option');
        option.value = link;
        option.textContent = link;
        linkList.appendChild(option);
    });
}

downloadSelectedButton.addEventListener('click', () => {
    const selectedLinks = Array.from(linkList.selectedOptions).map(option => option.value);
    downloadFiles(selectedLinks);
});

downloadAllButton.addEventListener('click', () => {
    const allVisibleLinks = Array.from(linkList.options).map(option => option.value);
    downloadFiles(allVisibleLinks);
});

function downloadFiles(links: string[]) {
    if (links.length === 0) {
        status.textContent = 'No files to download.';
        return;
    }

    status.textContent = `Downloading ${links.length} files...`;
    links.forEach((link, i) => {
        try {
            const filename = new URL(link).pathname.split('/').pop() || `download-${i}`;
            window.electronAPI.downloadFile(link, filename);
        } catch (error) {
            console.error(`Invalid URL for download: ${link}`);
        }
    });
    status.textContent = 'Download complete.';
}
