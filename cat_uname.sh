case "$(uname -m)" in
  x86_64)  arch="x86_64" ;;
  aarch64) arch="aarch64" ;;
  armv7l)  arch="armv7" ;;
  *)       echo "unsupported"; exit 1 ;;
esac

if ldd --version 2>&1 | grep -q musl; then
  libc="musl"
else
  libc="gnu"
fi

if [ "$arch" = "x86_64" ]; then
  file="*-${arch}-unknown-linux-${libc}.tar.gz"
elif [ "$arch" = "aarch64" ]; then
  file="*-${arch}-unknown-linux-${libc}.tar.gz"
else
  # armv7 的 glibc 版本叫 gnueabihf，musl 版本叫 musleabihf
  file="*-${arch}-unknown-linux-${libc}eabihf.tar.gz"
fi
echo "下载: $file"
