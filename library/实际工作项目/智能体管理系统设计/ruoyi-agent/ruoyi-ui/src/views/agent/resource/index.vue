<template>
  <div class="app-container">
    <el-form :model="queryParams" ref="queryForm" size="small" :inline="true" v-show="showSearch">
      <el-form-item label="资源名称" prop="resourceName">
        <el-input v-model="queryParams.resourceName" placeholder="请输入资源名称" clearable @keyup.enter.native="handleQuery" />
      </el-form-item>
      <el-form-item label="类型" prop="resourceType">
        <el-select v-model="queryParams.resourceType" placeholder="请选择类型" clearable>
          <el-option v-for="dict in dict.type.resource_type" :key="dict.value" :label="dict.label" :value="dict.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="分类" prop="categoryId">
        <treeselect v-model="queryParams.categoryId" :options="categoryOptions" :show-count="true" placeholder="请选择分类" style="width:200px" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="el-icon-search" size="mini" @click="handleQuery">搜索</el-button>
        <el-button icon="el-icon-refresh" size="mini" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" plain icon="el-icon-plus" size="mini" @click="handleAdd" v-hasPermi="['agent:resource:add']">新增</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="success" plain icon="el-icon-edit" size="mini" :disabled="single" @click="handleUpdate" v-hasPermi="['agent:resource:edit']">修改</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="danger" plain icon="el-icon-delete" size="mini" :disabled="multiple" @click="handleDelete" v-hasPermi="['agent:resource:remove']">删除</el-button>
      </el-col>
      <right-toolbar :showSearch.sync="showSearch" @queryTable="getList"></right-toolbar>
    </el-row>

    <el-table v-loading="loading" :data="resourceList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" align="center" />
      <el-table-column label="ID" align="center" prop="resourceId" width="70" />
      <el-table-column label="缩略图" align="center" width="80">
        <template slot-scope="scope">
          <el-image v-if="scope.row.thumbnailUrl && isImage(scope.row.resourceType)" 
            :src="scope.row.thumbnailUrl" :preview-src-list="[scope.row.fileUrl]" 
            style="width:50px;height:50px;object-fit:cover;border-radius:4px" />
          <el-avatar v-else :size="40" :icon="resourceIcon(scope.row.resourceType)" />
        </template>
      </el-table-column>
      <el-table-column label="资源名称" align="center" prop="resourceName" />
      <el-table-column label="类型" align="center" prop="resourceType" width="90">
        <template slot-scope="scope">
          <el-tag :type="resourceTypeTag(scope.row.resourceType)" size="small">
            {{ resourceTypeLabel(scope.row.resourceType) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="分类" align="center" prop="categoryId" width="120">
        <template slot-scope="scope">{{ getCategoryName(scope.row.categoryId) }}</template>
      </el-table-column>
      <el-table-column label="大小" align="center" prop="fileSize" width="100">
        <template slot-scope="scope">{{ formatFileSize(scope.row.fileSize) }}</template>
      </el-table-column>
      <el-table-column label="格式" align="center" prop="fileFormat" width="80" />
      <el-table-column label="尺寸" align="center" width="100">
        <template slot-scope="scope">{{ scope.row.width ? scope.row.width + 'x' + scope.row.height : '-' }}</template>
      </el-table-column>
      <el-table-column label="状态" align="center" prop="status" width="80">
        <template slot-scope="scope">
          <el-switch v-model="scope.row.status" active-value="0" inactive-value="1" @change="handleStatusChange(scope.row)" />
        </template>
      </el-table-column>
      <el-table-column label="创建时间" align="center" prop="createTime" width="160">
        <template slot-scope="scope">{{ parseTime(scope.row.createTime) }}</template>
      </el-table-column>
      <el-table-column label="操作" align="center" class-name="small-padding fixed-width" width="160">
        <template slot-scope="scope">
          <el-button size="mini" type="text" icon="el-icon-edit" @click="handleUpdate(scope.row)" v-hasPermi="['agent:resource:edit']">修改</el-button>
          <el-button size="mini" type="text" icon="el-icon-delete" style="color:#F56C6C" @click="handleDelete(scope.row)" v-hasPermi="['agent:resource:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total > 0" :total="total" :page.sync="queryParams.pageNum" :limit.sync="queryParams.pageSize" @pagination="getList" />

    <el-dialog :title="title" :visible.sync="open" width="700px" append-to-body>
      <el-form ref="form" :model="form" :rules="rules" label-width="100px">
        <el-row>
          <el-col :span="12">
            <el-form-item label="资源名称" prop="resourceName">
              <el-input v-model="form.resourceName" placeholder="请输入资源名称" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="类型" prop="resourceType">
              <el-select v-model="form.resourceType" placeholder="请选择类型" style="width:100%">
                <el-option v-for="dict in dict.type.resource_type" :key="dict.value" :label="dict.label" :value="dict.value" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row>
          <el-col :span="12">
            <el-form-item label="分类" prop="categoryId">
              <treeselect v-model="form.categoryId" :options="categoryOptions" :show-count="true" placeholder="请选择分类" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="格式" prop="fileFormat">
              <el-input v-model="form.fileFormat" placeholder="如：jpg, mp4, pdf" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="文件URL" prop="fileUrl">
          <el-input v-model="form.fileUrl" placeholder="请输入文件存储URL" />
        </el-form-item>
        <el-form-item label="缩略图URL" prop="thumbnailUrl">
          <el-input v-model="form.thumbnailUrl" placeholder="请输入缩略图URL（图片/视频）" />
        </el-form-item>
        <el-row>
          <el-col :span="8">
            <el-form-item label="宽度" prop="width">
              <el-input-number v-model="form.width" :min="0" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="高度" prop="height">
              <el-input-number v-model="form.height" :min="0" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="时长(秒)" prop="duration">
              <el-input-number v-model="form.duration" :min="0" :precision="2" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="标签" prop="tags">
          <el-input v-model="form.tags" placeholder="多个标签用逗号分隔" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="form.description" type="textarea" :rows="3" placeholder="请输入资源描述" />
        </el-form-item>
        <el-form-item label="元数据(JSON)" prop="metadataJson">
          <el-input v-model="form.metadataJson" type="textarea" :rows="3" placeholder='{"key":"value"}' />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio label="0">正常</el-radio>
            <el-radio label="1">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="请输入备注" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button type="primary" @click="submitForm">确 定</el-button>
        <el-button @click="cancel">取 消</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { listResource, getResource, addResource, updateResource, delResource } from '@/api/agent/resource'
import { treeCategory } from '@/api/agent/category'
import Treeselect from '@riophae/vue-treeselect'
import '@riophae/vue-treeselect/dist/vue-treeselect.css'

export default {
  name: 'DigitalResource',
  dicts: ['resource_type'],
  components: { Treeselect },
  data() {
    return {
      loading: false,
      showSearch: true,
      single: true,
      multiple: true,
      total: 0,
      resourceList: [],
      categoryOptions: [],
      title: '',
      open: false,
      queryParams: { pageNum: 1, pageSize: 10, resourceName: null, resourceType: null, categoryId: null },
      form: {},
      rules: {
        resourceName: [{ required: true, message: '资源名称不能为空', trigger: 'blur' }],
        resourceType: [{ required: true, message: '请选择类型', trigger: 'change' }]
      }
    }
  },
  created() {
    this.getList()
    this.getCategoryTree()
  },
  methods: {
    getList() {
      this.loading = true
      listResource(this.queryParams).then(response => {
        this.resourceList = response.rows
        this.total = response.total
        this.loading = false
      })
    },
    getCategoryTree() {
      treeCategory().then(response => {
        this.categoryOptions = this.handleTree(response.data, 'categoryId', 'parentId', 'children')
      })
    },
    getCategoryName(categoryId) {
      if (!categoryId) return '-'
      const find = (arr) => {
        for (const item of arr) {
          if (item.categoryId === categoryId) return item.categoryName
          if (item.children) {
            const name = find(item.children)
            if (name) return name
          }
        }
        return null
      }
      return find(this.categoryOptions) || '-'
    },
    isImage(type) { return ['image', 'video'].includes(type) },
    resourceIcon(type) {
      const map = { image: 'el-icon-picture', video: 'el-icon-video-camera', audio: 'el-icon-headset', 
        document: 'el-icon-document', code: 'el-icon-s-operation', model: 'el-icon-cpu', other: 'el-icon-files' }
      return map[type] || 'el-icon-files'
    },
    resourceTypeLabel(type) {
      const map = { image: '图片', video: '视频', audio: '音频', document: '文档', code: '代码', model: '模型', other: '其他' }
      return map[type] || type
    },
    resourceTypeTag(type) {
      const map = { image: 'primary', video: 'success', audio: 'warning', document: 'info', code: '', model: 'danger', other: 'info' }
      return map[type] || 'info'
    },
    formatFileSize(bytes) {
      if (!bytes) return '0 B'
      const k = 1024
      const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    },
    handleStatusChange(row) {
      const text = row.status === '0' ? '启用' : '禁用'
      this.$confirm('确认要' + text + '【' + row.resourceName + '】吗?', '警告', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(() => {
        updateResource({ resourceId: row.resourceId, status: row.status }).then(() => {
          this.$modal.msgSuccess(text + '成功')
        })
      }).catch(() => { row.status = row.status === '0' ? '1' : '0' })
    },
    handleQuery() { this.queryParams.pageNum = 1; this.getList() },
    resetQuery() { this.resetForm('queryForm'); this.handleQuery() },
    handleSelectionChange(selection) {
      this.single = selection.length !== 1
      this.multiple = !selection.length
      this.ids = selection.map(item => item.resourceId)
    },
    reset() { this.form = { status: '0' }; this.resetForm('form') },
    handleAdd() { this.reset(); this.open = true; this.title = '新增资源' },
    handleUpdate(row) {
      this.reset()
      const resourceId = row.resourceId || this.ids[0]
      getResource(resourceId).then(response => {
        this.form = response.data
        this.open = true
        this.title = '修改资源'
      })
    },
    submitForm() {
      this.$refs['form'].validate(valid => {
        if (valid) {
          if (this.form.resourceId != null) {
            updateResource(this.form).then(() => { this.$modal.msgSuccess('修改成功'); this.open = false; this.getList() })
          } else {
            addResource(this.form).then(() => { this.$modal.msgSuccess('新增成功'); this.open = false; this.getList() })
          }
        }
      })
    },
    cancel() { this.open = false; this.reset() },
    handleDelete(row) {
      const resourceIds = row.resourceId || this.ids
      this.$confirm('是否确认删除资源编号为【' + resourceIds + '】的数据项?', '警告', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(() => delResource(resourceIds)).then(() => { this.getList(); this.$modal.msgSuccess('删除成功') })
    }
  }
}
</script>
