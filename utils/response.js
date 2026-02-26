// 统一响应格式
const success = (res, data = null, message = '操作成功') => {
  res.json({
    code: 0,
    message,
    data,
    timestamp: Date.now()
  });
};

const error = (res, message = '操作失败', code = 1, statusCode = 400) => {
  res.status(statusCode).json({
    code,
    message,
    data: null,
    timestamp: Date.now()
  });
};

// 分页响应
const paginate = (res, list, pagination) => {
  res.json({
    code: 0,
    message: '操作成功',
    data: {
      list,
      pagination: {
        page: pagination.page,
        pageSize: pagination.pageSize,
        total: pagination.total,
        totalPages: Math.ceil(pagination.total / pagination.pageSize)
      }
    },
    timestamp: Date.now()
  });
};

module.exports = {
  success,
  error,
  paginate
};
