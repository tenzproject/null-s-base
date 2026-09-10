const width = window.screen.width;
const height = window.screen.height;
const ratio = width / height;

const tolerance = 0.05;
res = 0
if (Math.abs(ratio - (16 / 9)) < tolerance) {
    res = 0
} else if (Math.abs(ratio - (21 / 9)) < tolerance) {
    res = 1
}
if (res == 1){
    $("body").attr("style",`transform: scale(0.75);margin-top: -5.2vw;`)
}

window.addEventListener('message', function(e) {
    var data = e.data
    if (data.type == "balance"){
        $(".balance h1").text("$"+data.money)
    }
    if (data.type == "visible"){
        if (data.lang){
            const lang = data.lang
            $(".screen-home span").text(lang.welcome_title)
            $(".screen-home h1").html(lang.title)
            $(".screen-home p").text(lang.insert_card)

            $(".screen-end span").text(lang.msg_thanks)
            $(".screen-end h1").html(lang.title)
            $(".screen-end p").text(lang.msg_soon)

            $('.menu .atm-item.right.e p').contents().filter(function() {
                return this.nodeType === 3;
            }).replaceWith(lang.balance);
            $('.menu .atm-item.right.f p, .withdrawal .atm-item.right.h p').contents().filter(function() {
                return this.nodeType === 3;
            }).replaceWith(lang.withdraw);
            $('.menu .atm-item.right.g p, .deposit .atm-item.right.h p').contents().filter(function() {
                return this.nodeType === 3;
            }).replaceWith(lang.deposit);
            $('.menu .atm-item.right.h p').contents().filter(function() {
                return this.nodeType === 3;
            }).replaceWith(lang.exit);

            $('.balance .atm-item.left.d p, .deposit .atm-item.left.d p, .withdrawal .atm-item.left.d p, .withdrawal-pre .atm-item.left.d p, .balance .atm-item.left.d p').contents().filter(function() {
                return this.nodeType === 3;
            }).replaceWith(lang.back);

            $('.withdrawal-pre .atm-item.right.h p').contents().filter(function() {
                return this.nodeType === 3;
            }).replaceWith(lang.custom_input);
    
            $(".balance .abs span").html(lang.msg_balance)
            $(".withdrawal .abs span").html(lang.msg_withdraw)
            $(".deposit .abs span").html(lang.msg_deposit)
        }
        show_atm(data.data,data.atm)
    }

    if (data.type == "pickupmoney"){
        pickupmoney()
    }
    if (data.type == "putmoney"){
        putmoney()
    }

});

var cInput = false
var fInput = false
var isCard = false

function pickupmoney(){
    click_btn(0,".screen-end")
    $("#moneyCounter")[0].volume = 0.5
    $("#moneyCounter")[0].play()
    setTimeout(function() {
        $.post("https://BankATM/doCommand",JSON.stringify({type:"pickupmoney"}))
        setTimeout(function() {
            exit()
        }, 2500);
    }, 3000);
}

function putmoney(){
    click_btn(0,".screen-end")
    setTimeout(function() {
        $.post("https://BankATM/doCommand",JSON.stringify({type:"putmoney"}))
        setTimeout(function() {
            setTimeout(function() {$("#clickSound")[0].volume = 0.5;$("#clickSound")[0].play()}, 1000);
            exit()
        }, 2500);
    }, 0);
}

function show_atm(status,atm){
    if (status){
        $(".screen-home .min-loading").hide(0)
        $("body").removeClass()
        $("body").addClass(atm)
        var img = atm
        $(".screen img").attr("src",`assets/img/${img}.png`)
        $("html").show(0)
    }
    else{
        $(".scr").hide()
        $(".screen-home").show()
        $("html").hide(0)
    }
}

$(document).keydown(function(e) {
    if (e.key === 'Escape') {
        exit()
    }
});

function insert_card(){
    if (isCard){return}
    $.post("https://BankATM/doCommand",JSON.stringify({type:"card"}))
    
    setTimeout(function() {
        $("#cardInsert")[0].volume = 0.5
        $("#cardInsert")[0].play()
    }, 1300);
    setTimeout(function() {
        $(".screen-home .min-loading").show(0)
        setTimeout(function() {
            isCard = true
            $(".screen-home").fadeOut(100,function(){
                click_btn(0,".menu")
            })
        }, 800);
    }, 2000);
}

var s = null
function click_btn(self,change,force){
    if (self != 0){$("#clickSound")[0].volume = 0.5;$("#clickSound")[0].play()}
    if (!isCard){return}
    $(".scr").fadeOut(100,function(){})
    setTimeout(function() {
        restart_right_btns()
        $(change).fadeIn(100)
        if (change == ".balance"){
            $(".balance h1").text(". . . .")
            setTimeout(function() {$.post("https://BankATM/doCommand",JSON.stringify({type:"balance"}))}, 500);
            $($(".left-side button")[3]).attr("onclick",`click_btn(1,'.menu',true)`)
        }
        else if (change == ".menu"){
            $(".right-side").html(`
                <button onclick="click_btn(1,'.balance')"></button>
                <button onclick="click_btn(1,'.withdrawal-pre')"></button>
                <button onclick="click_btn(1,'.deposit')"></button>
                <button></button>
            `)
            $($(".right-side button")[3]).attr("onclick",`exit()`)
        }
        else if (change == ".screen-home"){
            $(change).find(".min-loading").hide()
        }
        else if (change == ".withdrawal-pre"){
            $($(".left-side button")[3]).attr("onclick",`click_btn(1,'.menu',true)`)
            $($(".right-side button")[3]).attr("onclick",`click_btn(1,'.withdrawal',true)`).prop("disabled",false)
            $($(".right-side button")[0]).attr("onclick",`withdraw(100)`).prop("disabled",false)
            $($(".right-side button")[1]).attr("onclick",`withdraw(1000)`).prop("disabled",false)
            $($(".right-side button")[2]).attr("onclick",`withdraw(10000)`).prop("disabled",false)
        }
        else if (change == ".withdrawal"){
            $(".wd").val("0")
            s = "withdraw"
            $($(".left-side button")[3]).attr("onclick",`click_btn(1,'.menu',true)`)
            $($(".right-side button")[3]).attr("onclick",`withdraw()`).prop("disabled",false)
        }
        else if (change == ".deposit"){
            $(".wd").val("0")
            s = "deposit"
            $($(".left-side button")[3]).attr("onclick",`click_btn(1,'.menu',true)`)
            $($(".right-side button")[3]).attr("onclick",`deposit()`).prop("disabled",false)
        }
        else{
            restart_right_btns()
        }
    }, 200);
}

function exit(){
    s = null
    setTimeout(function() {
        $("#cardInsert")[0].volume = 0.5
        $("#cardInsert")[0].play()
        click_btn(0,".screen-home")
        isCard = false
        cInput = false
        fInput = false
    }, 1000);
    $.post("https://BankATM/exit")
}

$(".numbers").on("click","button",function(){
    $("#clickSound")[0].volume = 0.5;$("#clickSound")[0].play()
    var curInput = $(".wd").val()
    var c = $(this).attr("num")
        if (c == -1){
            $(".wd").val("0")
            return
        }
    if (c == -2){
        if (s == "withdraw"){withdraw(curInput);}
        if (s == "deposit"){deposit(curInput);}
        return
    }
    if (c < 0){return}
    if (curInput === "0"){curInput = ""}
    $(".wd").val(curInput + c)
})

function deposit(count){
    if (!count){count = parseInt($(".deposit .wd").val())}
    count = parseInt(count)
    $.post("https://BankATM/doCommand",JSON.stringify({type:"deposit",money:count}))
}

function withdraw(count){
    if (!count){count = parseInt($(".wd").val())}
    count = parseInt(count)
    $.post("https://BankATM/doCommand",JSON.stringify({type:"withdraw",money:count}))
}

function restart_right_btns(){
    cInput = false
    $(".left-side").html(`
        <button></button>
        <button></button>
        <button></button>
        <button></button>
    `)

    $(".right-side").html(`
        <button></button>
        <button></button>
        <button></button>
        <button></button>
    `)
}

