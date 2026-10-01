无标题

提供了JdbcTemplate 来封装数据库jdbc操作细节： 
包括： 数据库连接\[打开/关闭\] ，异常转义 ，SQL执行 ，查询结果的转换

使用模板方式封装 jdbc数据库操作-固定流程的动作，提供丰富callback回调接口功能，方便用户自定义加工细节，更好模块化jdbc操作，简化传统的JDBC操作的复杂和繁琐过程。 

) 使用JdbcTemplate 更新(insert /update /delete)

int k = jdbcTemplate.update("UPDATE tblname SET prop=?,prop=?...", new Object\[\]{...});

jdbcTemplate.update("INSERT INTO tblname VALUES(?,?,..)", new Object\[\]{...},
	 new int\[\]{Types.VARCHAR,Types.NUMERIC});

jdbcTemplate.update("INSERT INTO tblname VALUES(?,?,..)",
        new PreparedStatementSetter(){
               public void setValues(PreparedStatement ps) throws SQLException{
                    ps.setLong(, user.getId());
                    ps.setString(, user.getName());
                    ps.setDate(, new java.sql.Date(new Date().getTime());
                    ps.setTimestamp(, new Timestamp(new Date().getTime());
               }
        }
);

) 使用JdbcTemplate 查询 (select)

final User user = new User();
jdbcTemplate.query("SELECT id,name,.. FROM tblname WHERE id=",
       new RowCallbackHandler(){
              public void processRow(ResultSet rs) throws SQLException{
                    user.setId(rs.getLong());
                    user.setName(rs.getString());
              }
      }
);

List uGroup = jdbcTemplate.query("SELECT id,name,.. FROM tblname WHERE igroup=",
     new RowMapper(){
            public Object mapRow(ResultSet rs,int no) throws SQLException{
                     User user = new User();
                     user.setId(rs.getLong());
                     user.setName(rs.getString());
                     return user ;
            }
     }
};

)使用JdbcTemplate 便捷方法

List uNames = jdbcTemplate.queryForList("SELECT name FROM tblname WHERE id>?",
	new Integer \[\]{}, String.class);

List<Map> uMapList = (List<Map>) jdbcTemplate.queryForList( "SELECT id, name FROM tblname WHERE id>?",
			 new Integer \[\]{});
for(Map<String,Object> uMap :uMapList){
      Integer id = uMap.get("id");
      String name = uMap.get("name");
};

String user = jdbcTemplate.queryForObject("SELECT name FROM tblname WHERE id=?",
	 new Integer \[\]{}, String.class );

int uNum = jdbcTemplate.queryForInt("SELECT count(\*) FROM tblname WHERE id>?",
	new Integer \[\]{});

)使用jdbc 操作类

a)扩展 MappingSqlQuery类

class JdbcQueryObject extends MappingSqlQuery { // extends SqlQuery
      public JdbcQueryObject (DataSource ds,String sql){
            this.setDataSource( ds );
            this.setSql( sql );
            this.declareParameter(new Sqlparameter("propName",
                Types.VARCHAR);// propName 提示作用
        this.compile();
      }
      public Object mapRow(ResultSet rs,int p) throws SQLException{
                 // ...
     }
}
JdbcQueryObject queryObj = new JdbcQueryObject( ds,
      "SELECT .. FROM tblName WHERE param=?");
List list = queryObj.execute(new Object\[\]{...});

b)使用 SqlFunction 类 查询单条结果

SqlFunction queryFun = new SqlFunction( ds,
      "select count(\*) from tblName where ..." ,new int\[\]{Types.CHAR,...} );
queryFun.compile();
queryFun.run(new Object\[\]{p,p,..});

c)使用 SqlUpdate 类 更新

SqlUpdate updateFunc = new SqlUpdate(ds ,"INSERT tblName ...");
updateFunc.declareParameter( new SqlParameter("prop",Types.CHAR) );
updateFunc.compile();
updateFunc.update(new String\[\]{s,s});

)支持jdbc 事务

spring的事务管理有两种方式：编程式事务、声明式事务

这里谈一下 基于数据库单一资源的编程式事务:

spring用实现TransactionDefinition接口的类定义事务的属性：传播行为；隔离级别；超时值；只读标志

默认实现为：DefaultTransactionDefinition类

PlatformTransactionManager tm =
new DataSourceTransactionManager(
            jdbcTemplate.getDataSource() );
TransactionStatus status = null;
try{
    //null 默认事务属性配置DefaultTransactionDefinition
    status = tm.getTransaction(null);
  for(final String wd: words){
   try {
     jdbcTemplate.update( insertWordSql,
          new PreparedStatementSetter(){

	public void setValues(PreparedStatement pstate)
                     throws SQLException {
	        	pstate.setString(, wd) ;
		pstate.setTimestamp(,
		new Timestamp( new Date().getTime() ));
	}
        }
     );

   } catch (DataAccessException e) {
       e.printStackTrace();
       //tm.rollback(status);
    }
    } // end for
} finally {
     tm.commit(status);
}

来源： [http://www.open-open.com/lib/view/openhtml](http://www.open-open.com/lib/view/openhtml)