#!/bin/bash

# Hàm in thông báo có màu
function print_info() {
    echo -e "\033[1;34m👉 $1\033[0m"
    sleep 3
}

function print_success() {
    echo -e "\033[0;32m✅ $1\033[0m"
    sleep 2
}

function print_warning() {
    echo -e "\033[1;33m⚠️ $1\033[0m"
    sleep 2
}

# Cập nhật hệ thống
echo -e "\n"
print_info "Bắt đầu cập nhật hệ thống..."
echo -e "\n"
apt update && apt upgrade -y
echo -e "\n"
print_success "Đã cập nhật xong."
echo -e "\n"

# Cài đặt các gói cơ bản
print_info "Tiếp tục cài đặt các gói cơ bản..."
echo -e "\n"
apt install -y openssh-server mc nano curl \
    mariadb-client mariadb-server \
    postgresql postgresql-contrib postgresql-client
echo -e "\n"
print_success "Cài đặt các gói xong."
echo -e "\n"

# Cài đặt Webmin
print_info "Đang cài đặt Webmin..."
echo -e "\n"
curl -o webmin-setup-repo.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh
yes | sh webmin-setup-repo.sh
apt-get install -y webmin --install-recommends
echo -e "\n"
print_success "Webmin đã được cài đặt."
echo -e "\n"

# Tạo user
print_info "Đang tạo user 'thanh' và gán mật khẩu..."
echo -e "\n"
adduser thanh --gecos "" --disabled-password
echo "thanh:110289" | chpasswd
echo -e "\n"
print_success "Tạo user và gán mật khẩu thành công."
echo -e "\n"

# Thêm user vào sudo
print_info "Thêm user 'thanh' vào nhóm sudo..."
echo -e "\n"
usermod -aG sudo thanh
print_success "User đã có quyền sudo."
echo -e "\n"

# Kiểm tra nhóm của user
print_info "Kiểm tra các nhóm của user:"
echo -e "\n"
groups thanh
sleep 2

# Cấu hình PostgreSQL
echo -e "\n"
print_info "Cấu hình PostgreSQL cho phép kết nối từ xa..."
echo -e "\n"
PG_VER=$(ls /etc/postgresql | grep -E '^[0-9]+$')
PG_HBA="/etc/postgresql/$PG_VER/main/pg_hba.conf"
if ! grep -q "0.0.0.0/0" "$PG_HBA"; then
    echo "host    all             all             0.0.0.0/0            md5" >> "$PG_HBA"
    print_success "Đã thêm dòng host vào $PG_HBA"
    echo -e "\n"
else
    print_warning "pg_hba.conf đã chứa dòng cho 0.0.0.0/0, bỏ qua."
    echo -e "\n"
fi

PG_CONF="/etc/postgresql/$PG_VER/main/postgresql.conf"
sed -i "s/^#listen_addresses = .*/listen_addresses = '*'/" "$PG_CONF"
print_success "Đã bật listen_addresses = '*' trong $PG_CONF"
echo -e "\n"

# Đặt mật khẩu cho user postgres
print_info "Gán mật khẩu cho user 'postgres'..."
echo -e "\n"
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"
echo -e "\n"
print_success "Đã gán mật khẩu cho user postgres."
echo -e "\n"

# Khởi động lại PostgreSQL
print_info "Khởi động lại dịch vụ PostgreSQL..."
echo -e "\n"
systemctl restart postgresql
print_success "PostgreSQL đã khởi động lại."
echo -e "\n"

# Kiểm tra IP của server
print_info "Kiểm tra IP của server..."
echo -e "\n"
IP=$(hostname -I | awk '{print $1}')
echo "IP của server là: $IP"
echo -e "\n"
print_success "Tất cả các bước đã hoàn tất!"
echo -e "\n"
