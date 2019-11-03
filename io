// <io> -*- C++ -*-
// A tiny header presenting common IO objcets
// Created By Mivik, 2019.11

#ifndef __DIMENX_IO_H_
#define __DIMENX_IO_H_

#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <dirent.h>
#include <assert.h>
#include <vector>

#include <sys/stat.h>
#include <linux/limits.h>

namespace dimenx {

#if defined(WIN32) || defined(_WIN32) 
#define PATH_SEPARATOR '\\'
#else
#define PATH_SEPARATOR '/'
#endif

struct FileStat {
private:
	struct stat info;
public:
	FileStat() {}
	FileStat(const char *path) {load(path);}
	inline bool load(const char *path) { return stat(path,&info)==0; }
	inline bool isFile() const { return S_ISREG(info.st_mode); }
	inline bool isDirectory() const { return S_ISDIR(info.st_mode); }
	inline bool isCharacterDevice() const { return S_ISCHR(info.st_mode); }
	inline bool isBlockDevice() const { return S_ISBLK(info.st_mode); }
	inline bool isLink() const { return S_ISLNK(info.st_mode); }
	inline bool isSocketFile() const { return S_ISSOCK(info.st_mode); }
	inline bool isFIFO() const { return S_ISFIFO(info.st_mode); }
	inline time_t getLastModifyTime() const { return info.st_mtime; }
	inline time_t getLastAccessTime() const { return info.st_atime; }
	inline time_t getLastStatusChangeTime() const { return info.st_ctime; }
	inline size_t getSize() const { return info.st_size; }
	inline uid_t getOwnerUID() const { return info.st_uid; }
	inline gid_t getOwnerGID() const { return info.st_gid; }
	inline nlink_t getHardLinkCount() const { return info.st_nlink; }
	inline dev_t getDeviceID() const { return info.st_dev; }
	inline dev_t getInodeID() const { return info.st_rdev; }
	inline blksize_t getBlockSize() const { return info.st_blksize; }
	inline blkcnt_t getBlockCount() const { return info.st_blocks; }
};

struct File;
struct FileFilter {
	virtual bool operator()(const char *parent, const char *name) const {
		int len=strlen(name);
		if (len==1&&name[0]=='.') return false;
		if (len==2&&name[0]=='.'&&name[1]=='.') return false;
		return true;
	}
};
struct FileStream {
private:
	FILE *file;
public:
	FileStream() {}
	FileStream(const char *path, const char *mode) { file=fopen(path,mode); }
	inline void reopen(const char *path, const char *mode) { freopen(path,mode,file); }
	inline void seek(const long &offset, const int &origin) { fseek(file,offset,origin); }
	inline void read(void *ptr, const size_t &itemSize, const size_t &itemCnt) { fread(ptr,itemSize,itemCnt,file); }
	inline void write(const void *ptr, const size_t &itemSize, const size_t &itemCnt) { fwrite(ptr,itemSize,itemCnt,file); }
	inline long tell() { return ftell(file); }
	inline void close() { fclose(file); }
	inline void putchar(const char &c) { fputc(c,file); }
	inline char getchar() { return fgetc(file); }
	inline int scanf(const char *format, ...) {
		va_list args;
		va_start(args,format);
		return vfscanf(file,format,args);
	}
	inline void printf(const char *format, ...) {
		va_list args;
		va_start(args,format);
		return vfprintf(file,format,args);
	}
	inline bool eof() { return feof(file); }
	inline int error() { return ferror(file); }
	inline void clearError() { ::clearerr(file); }
	inline void rewind() { ::rewind(file); }
};

struct File {
private:
	std::string path;
	FileStat *info;
	inline bool loadInfo() {
		if (!exists()) return 0;
		if (!info) {
			info=new FileStat();
			if (!info->load(path.c_str())) return 0;
		}
		return 1;
	}
	inline void updatePath() {
		int len = path.length();
		if ((*(path.end()-1))==PATH_SEPARATOR) this->path.erase(this->path.end()-1);
		if (info) info=0;
	}
public:
	File() {}
	File(const std::string &path) {setPath(path);}
	File(const char *path) {setCPath(path);}
	File(File &parent, const char *name) {
		assert(parent.isDirectory());
		path=parent.path;
		path+=PATH_SEPARATOR;
		path+=name;
		updatePath();
	}
	~File() {if(info)delete info;}
#define E if(!loadInfo())return 0
	inline bool exists() const { return access(path.c_str(),F_OK)==0; }
	inline bool canWrite() const { return access(path.c_str(),W_OK)==0; }
	inline bool canRead() const { return access(path.c_str(),R_OK)==0; }
	inline bool canExecute() const { return access(path.c_str(),X_OK)==0; }
	inline bool isFile() { E;return info->isFile(); }
	inline bool isDirectory() { E;return info->isDirectory(); }
	inline bool isCharacterDevice() { E;return info->isCharacterDevice(); }
	inline bool isBlockDevice() { E;return info->isBlockDevice(); }
	inline bool isLink() { E;return info->isLink(); }
	inline bool isSocketFile() { E;return info->isSocketFile(); }
	inline bool isFIFO() { E;return info->isFIFO(); }
	inline time_t getLastModifyTime() { E;return info->getLastModifyTime(); }
	inline time_t getLastAccessTime() { E;return info->getLastAccessTime(); }
	inline time_t getLastStatusChangeTime() { E;return info->getLastStatusChangeTime(); }
	inline size_t getSize() { E;return info->getSize(); }
	inline uid_t getOwnerUID() { E;return info->getOwnerUID(); }
	inline gid_t getOwnerGID() { E;return info->getOwnerGID(); }
	inline nlink_t getHardLinkCount() { E;return info->getHardLinkCount(); }
	inline dev_t getDeviceID() { E;return info->getDeviceID(); }
	inline dev_t getInodeID() { E;return info->getInodeID(); }
	inline blksize_t getBlockSize() { E;return info->getBlockSize(); }
	inline blkcnt_t getBlockCount() { E;return info->getBlockCount(); }
	inline FileStat getFileStat() { E;return *info; }
	inline std::string getPath() { return path; }
	inline const char *getCPath() { return path.c_str(); }
	inline void setPath(const std::string &path) {
		this->path=path;
		updatePath();
	}
	inline void setCPath(const char *path) {
		this->path=path;
		updatePath();
	}
	inline File getLinkedFile() {
		File ret(getLinkedCPath());
		return ret;
	}
	inline std::string getLinkedPath() {
		if (!isLink()) return "";
		std::string ret=getLinkedCPath();
		return ret;
	}
	inline const char *getLinkedCPath() {
		char ret[PATH_MAX];
		if (!isLink()) {
			ret[0]='\0';
			return ret;
		}
		readlink(path.c_str(),ret,PATH_MAX);
		return ret;
	}
	inline File getAbsoluteFile() {
		File ret(getAbsoluteCPath());
		return ret;
	}
	inline std::string getAbsolutePath() {
		std::string ret=getAbsoluteCPath();
		return ret;
	}
	inline const char *getAbsoluteCPath() {
		char ret[PATH_MAX];
		realpath(path.c_str(),ret);
		return ret;
	}
	std::vector<File> listFiles() {
		std::vector<File> ret;
		if (!isDirectory()) return ret;
		DIR *dir=opendir(path.c_str());
		if (!dir) return ret;
		dirent *ent;
		while ((ent=readdir(dir))) ret.push_back(*(new File(*this,ent->d_name)));
		return ret;
	}
	std::vector<File> listFiles(const FileFilter &filter) {
		std::vector<File> ret;
		if (!isDirectory()) return ret;
		DIR *dir=opendir(path.c_str());
		if (!dir) return ret;
		dirent *ent;
		const char *we=path.c_str();
		while ((ent=readdir(dir)))
			if (filter(we,ent->d_name)) ret.push_back(*(new File(*this,ent->d_name)));
		return ret;
	}
	std::string getName() {
		int ind=path.length()-1;
		while (ind>=0&&path[ind]!=PATH_SEPARATOR) --ind;
		return path.substr(ind+1);
	}
	inline bool rename(const File &f) { return ::rename(path.c_str(),f.path.c_str())==0; }
	inline FileStream open(const char *mode) { return FileStream(path.c_str(),mode); }
	inline bool remove() {
		if (isFile()) return unlink(path.c_str())==0;
		else if (isDirectory()) return rmdir(path.c_str())==0;
	}
#undef E
};

};

#endif