# Skill市场

> 模块：Skill系统
> 更新时间：2026-03-29

---

## 一、Skill元数据规范

```python
from dataclasses import dataclass, field
from typing import List, Dict, Optional
from datetime import datetime


@dataclass
class SkillMetadata:
    """Skill元数据"""
    name: str                          # 唯一标识
    version: str                       # 语义化版本号
    description: str                   # 一句话描述
    author: str                        # 作者
    license: str = "MIT"               # 开源协议
    tags: List[str] = field(default_factory=list)
    category: str = "general"          # 分类
    min_framework_version: str = "1.0" # 最低框架版本
    parameters: List[Dict] = field(default_factory=list)
    dependencies: List[str] = field(default_factory=list)
    homepage: str = ""
    repository: str = ""

    def to_manifest(self) -> Dict:
        """导出为skill.json格式"""
        return {
            "name": self.name,
            "version": self.version,
            "description": self.description,
            "author": self.author,
            "license": self.license,
            "tags": self.tags,
            "category": self.category,
            "minFrameworkVersion": self.min_framework_version,
            "parameters": self.parameters,
            "dependencies": self.dependencies,
            "homepage": self.homepage,
            "repository": self.repository,
        }
```

---

## 二、Skill发现与安装

```python
import hashlib
import json
from pathlib import Path


class SkillRegistry:
    """Skill市场注册中心"""

    def __init__(self, registry_url: str, local_dir: str):
        self.registry_url = registry_url
        self.local_dir = Path(local_dir)
        self.local_dir.mkdir(parents=True, exist_ok=True)

    async def search(self, keyword: str,
                     category: str = None) -> List[SkillMetadata]:
        """搜索Skill"""
        # 调用远程API搜索
        params = {"q": keyword}
        if category:
            params["category"] = category
        results = await self._api_get("/skills/search", params)
        return [SkillMetadata(**r) for r in results]

    async def install(self, name: str, version: str = "latest"):
        """安装Skill"""
        # 1. 获取Skill包信息
        pkg_info = await self._api_get(f"/skills/{name}/{version}")

        # 2. 下载包
        pkg_bytes = await self._download(pkg_info["downloadUrl"])

        # 3. 校验完整性
        actual_hash = hashlib.sha256(pkg_bytes).hexdigest()
        if actual_hash != pkg_info["sha256"]:
            raise ValueError("Package integrity check failed")

        # 4. 解压到本地目录
        skill_dir = self.local_dir / name / version
        self._extract(pkg_bytes, skill_dir)

        # 5. 安装依赖
        manifest = json.loads((skill_dir / "skill.json").read_text())
        for dep in manifest.get("dependencies", []):
            await self.install(dep)

        print(f"Installed {name}@{version}")

    def list_installed(self) -> List[SkillMetadata]:
        """列出已安装的Skill"""
        skills = []
        for skill_dir in self.local_dir.iterdir():
            if skill_dir.is_dir():
                manifest_path = skill_dir / "skill.json"
                if manifest_path.exists():
                    data = json.loads(manifest_path.read_text())
                    skills.append(SkillMetadata(**data))
        return skills

    async def _api_get(self, path: str, params: Dict = None) -> Any:
        """调用远程API"""
        # 实际实现中使用 aiohttp 或 httpx
        pass

    async def _download(self, url: str) -> bytes:
        """下载Skill包"""
        pass

    def _extract(self, pkg_bytes: bytes, target_dir: Path):
        """解压Skill包"""
        pass
```

---

## 三、版本管理

```python
from packaging.version import Version


class SkillVersionManager:
    """Skill版本管理"""

    def __init__(self, registry: SkillRegistry):
        self.registry = registry

    async def update(self, name: str) -> bool:
        """更新Skill到最新版本"""
        installed = self._get_installed_version(name)
        latest = await self._get_latest_version(name)

        if Version(latest) > Version(installed):
            await self.registry.install(name, latest)
            return True
        return False

    async def update_all(self) -> List[str]:
        """更新所有已安装的Skill"""
        updated = []
        for skill in self.registry.list_installed():
            if await self.update(skill.name):
                updated.append(skill.name)
        return updated

    def _get_installed_version(self, name: str) -> str:
        """获取已安装版本"""
        manifest_path = self.registry.local_dir / name / "skill.json"
        if manifest_path.exists():
            data = json.loads(manifest_path.read_text())
            return data["version"]
        return "0.0.0"

    async def _get_latest_version(self, name: str) -> str:
        """获取最新版本"""
        info = await self.registry._api_get(f"/skills/{name}/latest")
        return info["version"]
```

---

*下一步：MCP协议概述*
