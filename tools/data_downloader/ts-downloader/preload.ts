import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('electronAPI', {
    downloadFile: (url: string, filename: string) => ipcRenderer.send('download-file', { url, filename }),
});
