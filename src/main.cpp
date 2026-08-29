#include <fstream>
#include <sstream>
#include <filesystem>
#include <cstdlib>
#include <fmt/core.h>

namespace fs = std::filesystem;

// Статистика по одному файлу
struct FileStats {
    std::string name;
    std::string extension;
    uintmax_t sizeBytes = 0;
    size_t lines = 0;
    size_t words = 0;
    size_t chars = 0;
};

// Считает строки/слова/символы в текстовом файле
FileStats analyzeFile(const fs::path& path) {
    FileStats stats;
    stats.name = path.filename().string();
    stats.extension = path.extension().empty() ? "(no ext)" : path.extension().string();
    stats.sizeBytes = fs::file_size(path);

    std::ifstream file(path);
    if (!file.is_open()) {
        // Бинарный файл или нет прав на чтение — пропускаем подсчёт текста
        return stats;
    }

    std::string line;
    while (std::getline(file, line)) {
        stats.lines++;
        stats.chars += line.size();

        std::istringstream iss(line);
        std::string word;
        while (iss >> word) {
            stats.words++;
        }
    }

    return stats;
}

// Печатает результат по одному файлу в аккуратной таблице через fmt
void printStats(const FileStats& s) {
    fmt::print("{:<25} | ext: {:<10} | {} bytes | {} lines | {} words | {} chars\n",
               s.name, s.extension, s.sizeBytes, s.lines, s.words, s.chars);
}

// Рекурсивно обходит директорию и анализирует каждый файл
void scanDirectory(const fs::path& dirPath, bool recursive) {
    if (!fs::exists(dirPath) || !fs::is_directory(dirPath)) {
        fmt::print("Not a valid directory: {}\n", dirPath.string());
        return;
    }

    fmt::print("Scanning: {}\n", dirPath.string());
    fmt::print("{:-<90}\n", "");

    size_t totalFiles = 0;
    uintmax_t totalBytes = 0;

    auto processEntry = [&](const fs::directory_entry& entry) {
        if (entry.is_regular_file()) {
            FileStats stats = analyzeFile(entry.path());
            printStats(stats);
            totalFiles++;
            totalBytes += stats.sizeBytes;
        }
    };

    if (recursive) {
        for (const auto& entry : fs::recursive_directory_iterator(dirPath)) {
            processEntry(entry);
        }
    } else {
        for (const auto& entry : fs::directory_iterator(dirPath)) {
            processEntry(entry);
        }
    }

    fmt::print("{:-<90}\n", "");
    fmt::print("Total: {} files, {} bytes\n", totalFiles, totalBytes);
}

int main(int argc, char* argv[]) {
    // Приоритет: аргумент командной строки > переменная окружения SCAN_DIR > текущая директория
    std::string dirToScan;

    if (argc > 1) {
        dirToScan = argv[1];
    } else if (const char* envDir = std::getenv("SCAN_DIR")) {
        dirToScan = envDir;
    } else {
        dirToScan = fs::current_path().string();
    }

    bool recursive = (argc > 2 && std::string(argv[2]) == "--recursive");

    scanDirectory(dirToScan, recursive);

    return 0;
}