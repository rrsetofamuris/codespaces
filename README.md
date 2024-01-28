## A. Building
#### 1. Clone this repository
```sh
git clone https://github.com/rsuntk/android_kernel_samsung_a03-4.14-oss.git a03_kernel && cd a03_kernel
```
#### 2. On the kernel root, type:
```sh
bash build_kernel.sh
```
#### 3. Select the configurations
```
~ Select the build target: ltn=a035m, cis=a035f
TARGET_DEVICE=cis

rissu-cis_defconfig	       rissu-permissive-cis_defconfig
rissu-enforcing-cis_defconfig
-- NOTE: ENFORCING and PERMISSIVE DEFCONFIG ARE BROKEN. --
~ Select the defconfig.
DEFCONFIG=rissu-cis_defconfig

# If you're using low specs pc, its recommended to use 2 or 4 (depends on the processor cores and threads)
~ Allocate total threads for compiling
TOTAL_THREAD=2

## COMPILATIONS START ##
```
#### 4. Edit `arch/arm64/configs/rissu` (optional)
- You can change your kernel name by editing this defconfig line:
```
CONFIG_LOCALVERSION="-YourKernelName"
```
#### 5. Compiled kernel is ready at the kernel tree root.
## B. How to add [KernelSU](https://kernelsu.org) support
#### 1. First, add KernelSU to your kernel source tree:
- By using the official script (recommended)
```sh
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
```
- or, using Rissu's ksu_fetch.sh script
```sh
bash $(pwd)/Rissu/ksu_fetch.sh
```
#### 2. Disable KPROBE. Edit ```arch/arm64/configs/rissu/$TARGET_DEVICE/rissu-$TARGET_DEVICE_defconfig```, and follow these
> KPROBE sometimes broken in a few device, so we need to disable it and use manual integration.

```diff
-CONFIG_KPROBES=y
-CONFIG_HAVE_KPROBES=y
-CONFIG_KPROBE_EVENTS=y
+# CONFIG_KPROBES is not set
+# CONFIG_HAVE_KPROBES is not set
+# CONFIG_KPROBE_EVENTS is not set
+CONFIG_KSU=y
+# CONFIG_KSU_DEBUG is not set # if you a dev, then turn on this option for KernelSU debugging.
```
#### 3. Edit these file:
- **NOTE: 4.14 KernelSU patches is depends on these symbols:**
	- `do_execveat_common`
	- `faccessat`
	- `vfs_read`
	- `vfs_statx`
	- `input_handle_event`

- `do_execveat_common` at **fs/exec.c**
```diff
 /*
  * sys_execve() executes a new program.
  */
+#ifdef CONFIG_KSU
+extern bool ksu_execveat_hook __read_mostly;
+extern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,
+			void *envp, int *flags);
+extern int ksu_handle_execveat_sucompat(int *fd, struct filename **filename_ptr,
+				 void *argv, void *envp, int *flags);
+#endif
static int do_execveat_common(int fd, struct filename *filename,
			      struct user_arg_ptr argv,
			      struct user_arg_ptr envp,
			      int flags)
{
	char *pathbuf = NULL;
	struct linux_binprm *bprm;
	struct file *file;
 	struct files_struct *displaced;
 	int retval;
 
+#ifdef CONFIG_KSU
+	if (unlikely(ksu_execveat_hook))
+		ksu_handle_execveat(&fd, &filename, &argv, &envp, &flags);
+	else
+		ksu_handle_execveat_sucompat(&fd, &filename, &argv, &envp, &flags);
+#endif
 	if (IS_ERR(filename))
 		return PTR_ERR(filename);
```
- `faccessat` at **fs/open.c**
```diff
/*
 * access() needs to use the real uid/gid, not the effective uid/gid.
 * We do this by temporarily clearing all FS-related capabilities and
 * switching the fsuid/fsgid around to the real ones.
 */
+
+#ifdef CONFIG_KSU
+extern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,
+			 int *flags);
+#endif
SYSCALL_DEFINE3(faccessat, int, dfd, const char __user *, filename, int, mode)
{
 	const struct cred *old_cred;
	struct cred *override_cred;
	struct path path;
	struct inode *inode;
 	struct vfsmount *mnt;
 	int res;
 	unsigned int lookup_flags = LOOKUP_FOLLOW;
+	
+#ifdef CONFIG_KSU
+	ksu_handle_faccessat(&dfd, &filename, &mode, NULL);
+#endif
 
 	if (mode & ~S_IRWXO)	/* where's F_OK, X_OK, W_OK, R_OK? */
 		return -EINVAL;
```
- `vfs_read` at **fs/read_write.c**
```diff
+#ifdef CONFIG_KSU
+extern bool ksu_vfs_read_hook __read_mostly;
+extern int ksu_handle_vfs_read(struct file **file_ptr, char __user **buf_ptr,
+			size_t *count_ptr, loff_t **pos);
+#endif
+
ssize_t vfs_read(struct file *file, char __user *buf, size_t count, loff_t *pos)
{
 	ssize_t ret;
+	
+#ifdef CONFIG_KSU 
+	if (unlikely(ksu_vfs_read_hook))
+		ksu_handle_vfs_read(&file, &buf, &count, &pos);
+#endif
 
 	if (!(file->f_mode & FMODE_READ))
 		return -EBADF;
```
- `vfs_statx` at **fs/stat.c**
```diff
+#ifdef CONFIG_KSU
+extern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);
+#endif
+
int vfs_statx(int dfd, const char __user *filename, int flags,
	      struct kstat *stat, u32 request_mask)
{
	struct path path;
 	int error = -EINVAL;
 	unsigned int lookup_flags = LOOKUP_FOLLOW | LOOKUP_AUTOMOUNT;
 
+#ifdef CONFIG_KSU
+	ksu_handle_stat(&dfd, &filename, &flags);
+#endif

 	if ((flags & ~(AT_SYMLINK_NOFOLLOW | AT_NO_AUTOMOUNT |
 		       AT_EMPTY_PATH | KSTAT_QUERY_FLAGS)) != 0)
 		return -EINVAL;
```
- `input_handle_event` at **drivers/input/input.c**
```diff
+#ifdef CONFIG_KSU
+extern bool ksu_input_hook __read_mostly;
+extern int ksu_handle_input_handle_event(unsigned int *type, unsigned int *code, int *value);
+#endif

 static void input_handle_event(struct input_dev *dev,
 			       unsigned int type, unsigned int code, int value)
 {
	int disposition = input_get_disposition(dev, type, code, &value);
	
+#ifdef CONFIG_KSU
+	if (unlikely(ksu_input_hook))
+		ksu_handle_input_handle_event(&type, &code, &value);
+#endif

 	if (disposition != INPUT_IGNORE_EVENT && type != EV_SYN)
 		add_input_randomness(type, code, value);
```
- **See full KernelSU non-GKI integration documentations** [here](https://kernelsu.org/guide/how-to-integrate-for-non-gki.html)

#### 4. Build it again.

## C. Problem solving
#### Q: I get an error "drivers/kernelsu/Kconfig"
A: Make sure symlinked ksu folder are there.

#### Q: I get undefined reference at ksu related lines.
A: Check out/drivers/kernelsu, if everything not compiled then, check drivers/Makefile, make sure ```obj-$(CONFIG_KSU) += kernelsu/``` are there.
## D. Credit
- [Rissu](https://github.com/rsuntk) - Unified Kernel Tree
- [gauravv-x1](https://gitlab.com/gauravv-x1) - A03 Developer and Tester
- [KernelSU](https://kernelsu.org) - A kernel-based root solution for Android

