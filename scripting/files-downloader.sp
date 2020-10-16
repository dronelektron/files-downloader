#include <sourcemod>
#include <sdktools>

#define FILES_CONFIG_PATH "configs/files-downloader.txt"
#define FILES_CONFIG_ROOT_KEY "FilesDownloader"
#define FILES_CONFIG_DEFAULT_KEY "Default"

#define MAX_MAP_NAME_LENGTH 256

#define EXTENSION_KEY "Extensions"
#define EXTENSION_SEPARATOR ","
#define EXTENSION_MAX_AMOUNT 10
#define EXTENSION_MAX_LENGTH 5

public Plugin myinfo = {
    name = "Files downloader",
    author = "Dron-elektron",
    description = "Allows to download and cache files for players",
    version = "0.1.0",
    url = ""
}

public void OnMapStart() {
    char filesConfig[PLATFORM_MAX_PATH];

    BuildPath(Path_SM, filesConfig, sizeof(filesConfig), FILES_CONFIG_PATH);

    if (!FileExists(filesConfig)) {
        LogError("Files config is missing");

        return;
    }

    KeyValues config = new KeyValues(FILES_CONFIG_ROOT_KEY);

    if (!config.ImportFromFile(filesConfig)) {
        LogError("Files config parsing is failed");

        delete config;

        return;
    }

    ParseFilesConfig(config);

    delete config;
}

void ParseFilesConfig(KeyValues config) {
    char mapName[MAX_MAP_NAME_LENGTH];

    GetCurrentMap(mapName, sizeof(mapName));
    ParseSection(config, FILES_CONFIG_DEFAULT_KEY);
    ParseSection(config, mapName);
}

void ParseSection(KeyValues config, const char[] sectionName) {
    config.Rewind();

    if (!config.JumpToKey(sectionName, false)) {
        LogMessage("Section '%s' is not found", sectionName);

        return;
    }

    if (!config.GotoFirstSubKey(false)) {
        LogMessage("No files config for section '%s'", sectionName);

        return;
    }

    LogMessage("Parsing section '%s'", sectionName);

    do {
        char fileName[PLATFORM_MAX_PATH];
        char extensions[PLATFORM_MAX_PATH];

        config.GetSectionName(fileName, sizeof(fileName));
        config.GetString(EXTENSION_KEY, extensions, sizeof(extensions));

        AddFilesToDownloads(fileName, extensions);
    } while (config.GotoNextKey(false));
}

void AddFilesToDownloads(const char[] fileName, const char[] extensions) {
    char fullFileName[PLATFORM_MAX_PATH];
    char extensionsArray[EXTENSION_MAX_AMOUNT][EXTENSION_MAX_LENGTH];
    int extensionsAmount = ExplodeString(extensions, EXTENSION_SEPARATOR, extensionsArray, EXTENSION_MAX_AMOUNT, EXTENSION_MAX_LENGTH);

    for (int i = 0; i < extensionsAmount; i++) {
        if (!IsSupportedExtension(extensionsArray[i])) {
            LogMessage("Skipped unsupported extension '%s' for file '%s'", extensionsArray[i], fileName);

            continue;
        }

        Format(fullFileName, sizeof(fullFileName), "%s.%s", fileName, extensionsArray[i]);
        AddFileToDownloadsTable(fullFileName);
        PrecacheGeneric(fullFileName, true);
        LogMessage("Added '%s' file to downloads and cache", fullFileName);
    }
}

bool IsSupportedExtension(const char[] extension) {
    if (StrEqual(extension, "vtf") || StrEqual(extension, "vmt") || StrEqual(extension, "txt")) {
        return true;
    }

    return false;
}
