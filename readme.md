# Hướng dẫn sử dụng công cụ BAOPROVIP - SYSTEM MANAGEMENT

Công cụ này được thiết kế để tự động hóa các tác vụ quản lý và cài đặt hệ thống Windows.

## 1. Yêu cầu hệ thống

-   Hệ điều hành Windows 10 & 11.
-   Cần có quyền Administrator để chạy đầy đủ chức năng.

## 2. Cách khởi chạy

Để bắt đầu, hãy thực hiện các bước sau:

1.  Đi tới thư mục `Setup`.
2.  Tìm file `setup.bat`.
3.  Nhấp chuột phải vào file `setup.bat` và chọn **Run as administrator**.

Công cụ sẽ tự động kiểm tra và yêu cầu quyền Administrator. Một giao diện đồ họa (GUI) với các tùy chọn sẽ xuất hiện.


## 3. Chức năng chính: `[1] Run All`

Đây là chức năng cốt lõi của công cụ, cho phép thực hiện tất cả các tác vụ đã được định cấu hình một cách tự động.

-   **Mục đích**: Tự động hóa hoàn toàn quá trình cài đặt và cấu hình máy tính mới hoặc chuẩn hóa môi trường làm việc.
-   **Hoạt động**: Khi bạn nhấp vào nút `[1] Run All`, script sẽ gọi hàm `Invoke-RunAllOperations`. Hàm này sẽ đọc file `config.json` và thực hiện tuần tự các tác vụ được định nghĩa trong đó, bao gồm nhưng không giới hạn ở:
    -   Cài đặt các phần mềm cần thiết.
    -   Kích hoạt hoặc vô hiệu hóa các tính năng của Windows (Windows Features).
    -   Thực hiện các thay đổi về hệ thống (ví dụ: đổi tên máy, cài đặt password).
    -   Quản lý ổ đĩa.
    -   Cài đặt CrowdStrike.

> **Quan trọng**: Nội dung và thứ tự của các tác vụ được thực hiện bởi "Run All" phụ thuộc hoàn toàn vào cấu hình trong file `config.json` nằm cùng thư mục `Setup`. Hãy đảm bảo bạn đã tùy chỉnh file này cho phù hợp với nhu cầu trước khi chạy.

## 4. Các chức năng khác

Ngoài "Run All", công cụ còn cung cấp các module chức năng riêng lẻ:

-   **[2] Software**: Cài đặt các phần mềm riêng lẻ.
-   **[3] Power**: Tùy chọn về nguồn điện.
-   **[4] Volume**: Quản lý phân vùng ổ đĩa.
-   **[5] Activate**: Kích hoạt Windows/Office.
-   **[6] Features**: Bật/tắt các tính năng của Windows.
-   **[7] Rename**: Đổi tên máy tính.
-   **[8] Password**: Đặt mật khẩu cho người dùng.
-   **[9] Domain**: Quản lý Domain/Workgroup.
-   **[10] CrowdStrike**: Các tùy chọn liên quan đến CrowdStrike.

Bạn có thể chọn các chức năng này để thực hiện các tác vụ cụ thể thay vì chạy tất cả cùng một lúc.
