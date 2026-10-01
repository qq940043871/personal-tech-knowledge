<template>
  <div class="app-container">
    <el-row :gutter="20">
      <el-col :span="6" :xs="24">
        <div class="head-container">
          <el-input v-model="categoryName" placeholder="请输入分类名称" clearable size="small" prefix-icon="el-icon-search" style="margin-bottom: 20px" />
        </div>
        <div class="head-container">
          <el-tree :data="categoryOptions" :props="defaultProps" :expand-on-click-node="false"
            :filter-node-method="filterNode" ref="tree" default-expand-all highlight-current
            @node-click="handleNodeClick" />
        </div>
      </el-col>
      <el-col :span="18" :xs="24">
        <el-form :model="queryParams" ref="queryForm" size="small" :inline="true" v-show="showSearch">
          <el-form-item label="分类名称" prop="categoryName">
            <el-input v-model="queryParams.categoryName" placeholder="请输入分类名称" clearable @keyup.enter.native="handleQuery" />
          </el-form-item>
          <el-form-item label="状态" prop="status">
            <el-select v-model="queryParams.status" placeholder="请选择状态" clearable>
              <el-option label="正常" value="0" />
              <el-option label="停用" value="1" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" icon="el-icon-search" size="mini" @click="handleQuery">搜索</el-button>
            <el-button icon="el-icon-refresh" size="mini" @click="resetQuery">重置</el-button>
          </el-form-item>
        </el-form>

        <el-row :gutter="10" class="mb8">
          <el-col :span="1.5">
            <el-button type="primary" plain icon="el-icon-plus" size="mini" @click="handleAdd" v-hasPermi="['agent:category:add']">新增</el-button>
          </el-col>
          <el-col :span="1.5">
            <el-button type="info" plain icon="el-icon-sort" size="mini" @click="toggleExpandAll">展开/折叠</el-button>
          </el-col>
          <right-toolbar :showSearch.sync="showSearch" @queryTable="getList"></right-toolbar>
        </el-row>

        <el-table v-if="refreshTable" v-loading="loading" :data="categoryList" row-key="categoryId" :default-expand-all="isExpandAll"
          :tree-props="{children: 'children', hasChildren: 'hasChildren'}">
          <el-table-column label="分类名称" align="center" prop="categoryName" />
          <el-table-column label="图标" align="center" prop="categoryIcon" width="100">
            <template slot-scope="scope"><i :class="scope.row.categoryIcon || 'el-icon-folder'" /></template>
          </el-table-column>
          <el-table-column label="排序" align="center" prop="sortOrder" width="80" />
          <el-table-column label="状态" align="center" prop="status" width="80">
            <template slot-scope="scope">
              <el-tag :type="scope.row.status === '0' ? 'success' : 'danger'" size="small">
                {{ scope.row.status === '0' ? '正常' : '停用' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="创建时间" align="center" prop="createTime" width="160">
            <template slot-scope="scope">{{ parseTime(scope.row.createTime) }}</template>
          </el-table-column>
          <el-table-column label="操作" align="center" class-name="small-padding fixed-width" width="200">
            <template slot-scope="scope">
              <el-button size="mini" type="text" icon="el-icon-edit" @click="handleUpdate(scope.row)" v-hasPermi="['agent:category:edit']">修改</el-button>
              <el-button size="mini" type="text" icon="el-icon-plus" @click="handleAdd(scope.row)" v-hasPermi="['agent:category:add']">新增</el-button>
              <el-button size="mini" type="text" icon="el-icon-delete" style="color:#F56C6C" @click="handleDelete(scope.row)" v-hasPermi="['agent:category:remove']">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-col>
    </el-row>

    <el-dialog :title="title" :visible.sync="open" width="600px" append-to-body>
      <el-form ref="form" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="上级分类" prop="parentId">
          <treeselect v-model="form.parentId" :options="categoryOptions" :normalizer="normalizer" :show-count="true" placeholder="选择上级分类" />
        </el-form-item>
        <el-form-item label="分类名称" prop="categoryName">
          <el-input v-model="form.categoryName" placeholder="请输入分类名称" />
        </el-form-item>
        <el-form-item label="分类图标" prop="categoryIcon">
          <el-input v-model="form.categoryIcon" placeholder="请输入图标类名，如：el-icon-folder" />
        </el-form-item>
        <el-form-item label="显示排序" prop="sortOrder">
          <el-input-number v-model="form.sortOrder" controls-position="right" :min="0" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio label="0">正常</el-radio>
            <el-radio label="1">停用</el-radio>
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
import { listCategory, getCategory, addCategory, updateCategory, delCategory } from '@/api/agent/category'
import Treeselect from '@riophae/vue-treeselect'
import '@riophae/vue-treeselect/dist/vue-treeselect.css'

export default {
  name: 'ResourceCategory',
  components: { Treeselect },
  data() {
    return {
      loading: false,
      showSearch: true,
      categoryList: [],
      categoryOptions: [],
      isExpandAll: true,
      refreshTable: true,
      categoryName: '',
      title: '',
      open: false,
      queryParams: { categoryName: null, status: null },
      form: {},
      defaultProps: { children: 'children', label: 'categoryName' },
      rules: {
        parentId: [{ required: true, message: '上级分类不能为空', trigger: 'blur' }],
        categoryName: [{ required: true, message: '分类名称不能为空', trigger: 'blur' }]
      }
    }
  },
  watch: {
    categoryName(val) { this.$refs.tree.filter(val) }
  },
  created() {
    this.getList()
  },
  methods: {
    getList() {
      this.loading = true
      listCategory(this.queryParams).then(response => {
        this.categoryList = this.handleTree(response.rows, 'categoryId', 'parentId')
        this.categoryOptions = [{ categoryId: 0, categoryName: '根分类', children: this.categoryList }]
        this.loading = false
      })
    },
    filterNode(value, data) {
      if (!value) return true
      return data.categoryName.indexOf(value) !== -1
    },
    handleNodeClick(data) {
      this.queryParams.parentId = data.categoryId
      this.handleQuery()
    },
    normalizer(node) {
      if (node.children && !node.children.length) delete node.children
      return { id: node.categoryId, label: node.categoryName, children: node.children }
    },
    toggleExpandAll() {
      this.refreshTable = false
      this.isExpandAll = !this.isExpandAll
      this.$nextTick(() => { this.refreshTable = true })
    },
    handleQuery() { this.getList() },
    resetQuery() { this.resetForm('queryForm'); this.handleQuery() },
    reset() {
      this.form = { parentId: 0, sortOrder: 0, status: '0' }
      this.resetForm('form')
    },
    handleAdd(row) {
      this.reset()
      if (row != null && row.categoryId) {
        this.form.parentId = row.categoryId
      } else {
        this.form.parentId = 0
      }
      this.open = true
      this.title = '新增分类'
    },
    handleUpdate(row) {
      this.reset()
      getCategory(row.categoryId).then(response => {
        this.form = response.data
        this.open = true
        this.title = '修改分类'
      })
    },
    submitForm() {
      this.$refs['form'].validate(valid => {
        if (valid) {
          if (this.form.categoryId != null) {
            updateCategory(this.form).then(() => { this.$modal.msgSuccess('修改成功'); this.open = false; this.getList() })
          } else {
            addCategory(this.form).then(() => { this.$modal.msgSuccess('新增成功'); this.open = false; this.getList() })
          }
        }
      })
    },
    cancel() { this.open = false; this.reset() },
    handleDelete(row) {
      this.$confirm('是否确认删除分类【' + row.categoryName + '】?', '警告', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(() => delCategory(row.categoryId)).then(() => { this.getList(); this.$modal.msgSuccess('删除成功') })
    }
  }
}
</script>
