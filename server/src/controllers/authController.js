const { register, login, changePassword } = require('../services/authService');

/**
 * 注册
 */
async function doRegister(req, res) {
  try {
    const { username, password, nickname } = req.body;
    const result = await register(username, password, nickname);

    if (!result.success) {
      return res.status(400).json({ code: 400, message: result.message });
    }

    res.json({ code: 200, message: result.message, data: result.data });
  } catch (error) {
    console.error('注册失败:', error);
    res.status(500).json({ code: 500, message: '注册失败' });
  }
}

/**
 * 登录
 */
async function doLogin(req, res) {
  try {
    const { username, password } = req.body;
    const result = await login(username, password);

    if (!result.success) {
      return res.status(401).json({ code: 401, message: result.message });
    }

    res.json({ code: 200, message: result.message, data: result.data });
  } catch (error) {
    console.error('登录失败:', error);
    res.status(500).json({ code: 500, message: '登录失败' });
  }
}

/**
 * 获取当前用户信息
 */
async function getProfile(req, res) {
  try {
    const { pool } = require('../config/db');
    const [rows] = await pool.execute(
      'SELECT id, username, nickname, role, created_at FROM users WHERE id = ?',
      [req.user.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ code: 404, message: '用户不存在' });
    }

    res.json({ code: 200, data: rows[0] });
  } catch (error) {
    res.status(500).json({ code: 500, message: '获取信息失败' });
  }
}

/**
 * 修改密码
 */
async function doChangePassword(req, res) {
  try {
    const { oldPassword, newPassword } = req.body;
    const result = await changePassword(req.user.id, oldPassword, newPassword);

    if (!result.success) {
      return res.status(400).json({ code: 400, message: result.message });
    }

    res.json({ code: 200, message: result.message });
  } catch (error) {
    res.status(500).json({ code: 500, message: '修改失败' });
  }
}

/** 校验颜色格式：接受 #RRGGBB 或 #RGB */
function isValidColor(color) {
  return typeof color === 'string' && /^#[0-9a-fA-F]{3}([0-9a-fA-F]{3})?$/.test(color);
}

/**
 * 获取用户界面设置（背景色 / 字体颜色）
 */
async function getSettings(req, res) {
  try {
    const { pool } = require('../config/db');
    const [rows] = await pool.execute(
      'SELECT bg_color, text_color FROM users WHERE id = ?',
      [req.user.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ code: 404, message: '用户不存在' });
    }

    res.json({
      code: 200,
      data: {
        bgColor: rows[0].bg_color || '#E7DFCA',
        textColor: rows[0].text_color || '#000000',
      },
    });
  } catch (error) {
    console.error('获取设置失败:', error);
    res.status(500).json({ code: 500, message: '获取设置失败' });
  }
}

/**
 * 保存用户界面设置
 */
async function updateSettings(req, res) {
  try {
    const { pool } = require('../config/db');
    const bgColor = isValidColor(req.body.bgColor) ? req.body.bgColor : null;
    const textColor = isValidColor(req.body.textColor) ? req.body.textColor : null;

    if (!bgColor && !textColor) {
      return res.status(400).json({ code: 400, message: '颜色格式无效' });
    }

    // 动态拼接：只更新传入了合法值的字段
    const sets = [];
    const params = [];
    if (bgColor) { sets.push('bg_color = ?'); params.push(bgColor.toUpperCase()); }
    if (textColor) { sets.push('text_color = ?'); params.push(textColor.toUpperCase()); }
    params.push(req.user.id);

    await pool.execute(`UPDATE users SET ${sets.join(', ')} WHERE id = ?`, params);

    res.json({ code: 200, message: '设置已保存' });
  } catch (error) {
    console.error('保存设置失败:', error);
    res.status(500).json({ code: 500, message: '保存设置失败' });
  }
}

module.exports = { doRegister, doLogin, getProfile, doChangePassword, getSettings, updateSettings };
