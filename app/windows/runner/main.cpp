#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "flutter_window.h"
#include "utils.h"

// Flutter 引擎依赖 exe 同目录的 data 文件夹（app.so / icudtl.dat 等）。
// 很多人只拷贝了 exe 和 DLL，进程会立即退出且没有任何提示，这里明确告知。
static bool HasFlutterData() {
  wchar_t exe_path[MAX_PATH];
  DWORD len = ::GetModuleFileNameW(nullptr, exe_path, MAX_PATH);
  if (len == 0 || len == MAX_PATH) return true;
  std::wstring dir(exe_path, len);
  size_t slash = dir.find_last_of(L"\\/");
  if (slash != std::wstring::npos) dir.resize(slash + 1);
  std::wstring data = dir + L"data\\icudtl.dat";
  return ::GetFileAttributesW(data.c_str()) != INVALID_FILE_ATTRIBUTES;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!HasFlutterData()) {
    ::MessageBoxW(
        nullptr,
        L"启动失败：缺少 data 文件夹。\n\n"
        L"请把下载的压缩包完整解压，直接运行解压后文件夹里的「良扑.exe」。\n"
        L"不要单独拷贝 exe —— data 文件夹和同目录的 DLL 必须一起保留。",
        L"良扑", MB_ICONERROR | MB_OK);
    return EXIT_FAILURE;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  // Phone-like initial window size (logical pixels).
  Win32Window::Size size(408, 686);
  if (!window.Create(L"liangpu_app", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
