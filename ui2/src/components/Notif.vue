<template>
  <div>
    <div class="notif-container">
      <transition-group name="list">
        <div v-for="notif in notifs" class="outer" :key="notif.id">
          <div class="item d-flex align-items-center" :class="{ ['item-' + notif.type]: true, }">
            <div class="icon">
              <i class="fa" :class="{ ['fa-' + notif.icon]: true, }"></i>
            </div>
            <div class="body">
              <h5>{{ notif.title }}</h5>
              <p>{{ notif.body }}</p>
            </div>
            <div class="x" v-on:click="hide(notif.id)">
              <i class="fa fa-times" aria-hidden="true"></i>
            </div>
          </div>
        </div>
      </transition-group>
    </div>
  </div>
</template>

<style scoped>
.item, .item.item-success {
  background: #07D8E0;
}
.item, .item.item-warn {
  background: #F8B500;
}
.item, .item.item-error {
  background: #E83929;
}


.notif-container {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  color: white;
  z-index: 1500;
  width: 30rem;
}
.item {
  height: 8rem;
  opacity: .8;
  border-radius: 10px;
  transition: opacity 300ms ease;
  position: relative;
  margin-top: 1rem;
}
.item:hover {
  opacity: 1;
}
.icon {
  font-size: 5rem;
  padding: 0 2rem;
  text-align: center;
}
.body {
  padding-right: 2rem;
}
.body h5 {
  font-size: 1rem;
}
.body p {
  margin: 0;
  font-size: .8rem;
}
.x {
  position: absolute;
  top: 0rem;
  right: 0rem;
  font-size: 1.6rem;
  padding: 0.6rem;
  cursor: pointer;
  line-height: 1;
}


.outer, .list-move {
  transition: all 500ms;
  position: relative;
}
.outer.list-enter, .outer.list-leave-to {
  opacity: 0;
  transform: translateX(10rem);
}
.outer.list-leave-to {
  height: 0;
}
.outer.list-enter-to, .outer.list-leave {
  height: 8rem;
}
.outer.list-leave-active .item {
  position: absolute;
  bottom: 0rem;
}
</style>

<script>
/*
Notifコンポーネントは、EventBusからイベントを受け取り、通知の表示を行います。

通知の表示を行うサンプルは以下のとおりです。

```js
import { Emit, PUSH_NOTIF } from '../utils/EventBus'
Emit(PUSH_NOTIF, {
  type: 'error',  // success/warn/error
  icon: 'warning',  // fontawsomeのアイコン名
  title: '設定の更新に失敗しました。',  // タイトル
  detail: 'ドメインチェックが失敗したため、サイトを有効にできません。',  // エラー文など
  key: 'setting', // 削除等を行う時の基準キー
  autoClose: false,  // 自動的に表示を消す
});
```

`autoClose` がtrueの場合、 `this.timeout` ミリ秒で通知を消します。
指定がない場合は、 `type` がerror,warnの際はfalse・successの場合はtrueがデフォルトで指定されます。

通知を消すサンプルは以下のとおりです。

```js
import { Emit, PUSH_NOTIF, REMOVE_NOTIF } from '../utils/EventBus'
Emit(REMOVE_NOTIF, msg => msg.key === 'setting');
```

REMOVE_NOTIFイベントでは、通知のインデックス番号・message => boolな関数を引数に指定できます。
ここでは、上に指定したkeyを持つ通知のみ消しています。

*/


import { API } from '../utils/Api'
import { Subscribe, PUSH_NOTIF, REMOVE_NOTIF } from '../utils/EventBus'
import { mapGetters } from 'vuex'

export default {
  name: '',
  data () {
    return {
      notifs: [
      ],
      incr: 1,
      pushSubscriber: Subscribe(PUSH_NOTIF, opt => { this.notify(opt) }),
      removeSubscriber: Subscribe(REMOVE_NOTIF, fn => { this.hide(fn) }),
      refreshInterval: setInterval(_ => this.refresh(), 500),
      timeout: 3000, // autoclose ms
      useBrowserNotification: false,
    }
  },
  asyncData: {
  },
  computed: {
    ...mapGetters([
      'contest',
      'session',
    ]),
  },
  watch: {
  },
  mounted () {
    if ('Notification' in window) {
      Notification.requestPermission().then((result) => {
        if (result === 'granted') {
          this.useBrowserNotification = true;
        }
      });
    }
  },
  beforeDestroy () {
    this.pushSubscriber.off();
    this.removeSubscriber.off();
    clearInterval(this.refreshInterval);
  },
  destroyed () {
  },
  methods: {
    notify (message) {
      if (message.type !== 'api') {
        let title = message.title;
        let body = message.detail;

        this.append(title, body, message.type);

        return;
      }

      // let notify_payload = JSON.parse(message.detail);
      let type, resource_id, state, data;
      ({type, resource_id, state, data} = JSON.parse(message.detail));

      const STATE_CREATED = 'created';
      const STATE_UPDATED = 'updated';

      switch (type) {
        case 'answer':
          if (state === STATE_CREATED) {
            this.notifyBrowser(
              '解答が投稿されました',
              '',
              { name: 'problem-answers', params: { id: data.problem_id, team: data.team_id } }
            );
            break;
          }
          break;
        case 'issue-comment':
          if (state === STATE_CREATED) {
            this.notifyBrowser(
              '質問にコメントが投稿されました',
              '',
              { name: 'problem-issues', params: { id: data.problem_id, team: data.team_id, issue: data.issue_id } }
            );
            break;
          }
          break;
        case 'problem-comment':
          if (state === STATE_CREATED) {
            this.notifyBrowser(
              '問題の補足が追加されました',
              '',
              { name: 'problem-detail', params: { id: data.problem_id } }
            );
            break;
          }
          break;
        case 'score':
          if (state === STATE_CREATED) {
            let notify_at = new Date(data.notify_at);
            let notify_delay = notify_at - new Date();

            setTimeout(() => {
              // checks score existence and can read
              API.getAnswer(resource_id).then(answer => {
                if (!answer.score) return;

                this.notifyBrowser(
                  '解答の採点結果が公開されました',
                  '',
                  { name: 'problem-answers', params: { id: data.problem_id, team: data.team_id } }
                );
              });
            }, notify_delay);

            break;
          }
          break;
        case 'notice':
          switch (state) {
            case STATE_CREATED:
              this.notifyBrowser(
                'お知らせが公開されました',
                '',
                { name: 'dashboard' }
              );
              break;
            case STATE_UPDATED:
              this.notifyBrowser(
                'お知らせが更新されました',
                '',
                { name: 'dashboard' }
              );
              break;
          }
          break;
        default:
          break;
      }
    },
    notifyBrowser (title, body, route_to, type = 'api') {
      // try browser notification if allowed
      if (this.useBrowserNotification) {
        let notif = new Notification(
          title,
          {
            body: body,
          }
        );
        let router = this.$router;
        if (route_to) {
          notif.addEventListener('click', () => { router.push(route_to); });
        }
      } else {
        this.append(title, body, type);
      }
    },
    append (title, body, type) {
      var autoClose;
      var icon;
      switch (type) {
        case 'error':
        case 'warn':
          icon = 'warning';
          autoClose = false;
          break;
        case 'api':
          icon = 'comments';
          autoClose = false;
          break;
        default:
        case 'success':
          icon = 'check';
          autoClose = true;
          break;
      }

      var includeIdMessage = {
        title,
        body,
        type,
        id: this.incr++,
        timestamp: Date.now(),
        autoClose,
        icon,
      }
      this.notifs.push(includeIdMessage);
    },
    hide (cond) {
      var fn;
      if (typeof cond === 'number') {
        fn = n => n.id === cond;
      } else if (typeof cond === 'function') {
        fn = cond
      } else {
        console.warn('[Notif] hide cond must number/function');
        return;
      }
      this.notifs = this.notifs.filter(s => !fn(s));
    },
    refresh () {
      this.hide(msg => msg.autoClose && (msg.timestamp + this.timeout < Date.now()));
    },
  },
}
</script>
