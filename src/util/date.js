(function(exports){

	exports = Date.prototype.format=function(fmt) {
		var o = {
			"M+" : this.getMonth()+1, //月份
			"d+" : this.getDate(), //日
			"h+" : this.getHours()%12 == 0 ? 12 : this.getHours()%12, //小时
			"H+" : this.getHours(), //小时
			"m+" : this.getMinutes(), //分
			"s+" : this.getSeconds(), //秒
			"q+" : Math.floor((this.getMonth()+3)/3), //季度
			"S" : this.getMilliseconds() //毫秒
		};
		var week = {
			"0" : "\u65e5",
			"1" : "\u4e00",
			"2" : "\u4e8c",
			"3" : "\u4e09",
			"4" : "\u56db",
			"5" : "\u4e94",
			"6" : "\u516d"
		};
		if(/(y+)/.test(fmt)){
			fmt=fmt.replace(RegExp.$1, (this.getFullYear()+"").substr(4 - RegExp.$1.length));
		}
		if(/(E+)/.test(fmt)){
			fmt=fmt.replace(RegExp.$1, ((RegExp.$1.length>1) ? (RegExp.$1.length>2 ? "\u661f\u671f" : "\u5468") : "")+week[this.getDay()+""]);
		}
		for(var k in o){
			if(new RegExp("("+ k +")").test(fmt)){
				fmt = fmt.replace(RegExp.$1, (RegExp.$1.length==1) ? (o[k]) : (("00"+ o[k]).substr((""+ o[k]).length)));
			}
		}
		return fmt;
	}
	/*
	 exports = Date.prototype.parseDate = function(fmt){
	 return fmt;
	 }
	 */
	Date.parseDate = function(time){
		if (!time)
			return false;
		var str = /^(?:19|20)[0-9][0-9]-(?:(?:[1-9])|(?:(?:0[1-9])|(?:1[0-2])))-(?:(?:[1-9])|(?:(?:[0-2][1-9])|(?:[1-3][0-1])))(?:|( (?:(?:[0-2][0-3])|(?:[0-1][0-9]))(?:|:[0-5][0-9](?:|:[0-5][0-9]))))$/;
		if(str.test(time))
		{
			var y,mo,d,h,mi,s;
			var arr = time.split(' ');
			var ymd = arr[0].split('-');
			y = parseInt(ymd[0], 10);
			mo = parseInt(ymd[1], 10) - 1;
			d = parseInt(ymd[2], 10);
			h = 0;
			mi = 0;
			s = 0;
			if (arr.length == 2)
			{
				var hms = arr[1].split(':');
				h = hms[0]?parseInt(hms[0], 10):0;
				mi = hms[1]?parseInt(hms[1], 10):0;
				s = hms[2]?parseInt(hms[2], 10):0;
			}
			var datetime = new Date(y,mo,d,h,mi,s);
			var unixtime = datetime.getTime();
			return unixtime;
		}
		return false;
	}
})(typeof exports === 'undefined'? this: exports);

exports.parseDate = function(time){
	if (!time)
		return null;
	var str = /^(?:19|20)[0-9][0-9]-(?:(?:[1-9])|(?:(?:0[1-9])|(?:1[0-2])))-(?:(?:[1-9])|(?:(?:[0-2][1-9])|(?:[1-3][0-1])))(?:|( (?:(?:[0-2][0-3])|(?:[0-1][0-9]))(?:|:[0-5][0-9](?:|:[0-5][0-9]))))$/;
	if(str.test(time))
	{
		var y,mo,d,h,mi,s;
		var arr = time.split(' ');
		var ymd = arr[0].split('-');
		y = parseInt(ymd[0], 10);
		mo = parseInt(ymd[1], 10) - 1;
		d = parseInt(ymd[2], 10);
		h = 0;
		mi = 0;
		s = 0;
		if (arr.length == 2)
		{
			var hms = arr[1].split(':');
			h = hms[0]?parseInt(hms[0], 10):0;
			mi = hms[1]?parseInt(hms[1], 10):0;
			s = hms[2]?parseInt(hms[2], 10):0;
		}
		return new Date(y,mo,d,h,mi,s);
	}
	return null;
}