const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/communityController');
const { requireAuth, optionalAuth } = require('../middleware/auth');

// 挑战营
router.get('/camps', ctrl.getCampList);
router.get('/camps/:userId/my', ctrl.getMyCamp);
router.post('/camps/:userId/join', ctrl.joinCamp);
router.post('/camps/:userId/checkin', ctrl.checkInCamp);
router.get('/camps/:campId/stats', ctrl.getCampStats);
router.post('/camps/:userId/leave', ctrl.leaveCamp);

// 话题圈
router.get('/posts', optionalAuth, ctrl.getPostList);
router.post('/posts/:userId', ctrl.createPost);
router.post('/posts/:postId/like', requireAuth, ctrl.likePost);

module.exports = router;
