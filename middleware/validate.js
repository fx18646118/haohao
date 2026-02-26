const { validationResult } = require('express-validator');

// 验证请求参数
const validate = (validations) => {
  return async (req, res, next) => {
    // 执行所有验证
    await Promise.all(validations.map(validation => validation.run(req)));

    const errors = validationResult(req);
    if (errors.isEmpty()) {
      return next();
    }

    const errorMessages = errors.array().map(err => ({
      field: err.path,
      message: err.msg
    }));

    return res.status(400).json({
      code: 400,
      message: '请求参数错误',
      data: { errors: errorMessages }
    });
  };
};

module.exports = {
  validate
};
