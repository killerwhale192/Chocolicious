class ClaimsController < ApplicationController
  def addremark
    @rejectclaim = Claim.find_by_id(params[:id])
    @status = params[:status]
  end

  def newclaim
    @new_claim = Claim.new
    clubid = session[:club]
    control = BudgetControl.find_by_id(2)
    year = control.year
    semester = control.semester
    @events = Budget.where(clubid:clubid, year:year, semester:semester)
    @grouped_expense = {
      'Assets maintenance and repair' => [['Equipment with life-span of > 1 year','1']],
      'Assets purchases (Equipment with life-span of > 1 year)' => [['Assets purchases <= $100','2'],['Assets purchases $100 < X < $500','3'],['Assets purchases > $500','4']],
      'Attire' => [['Attire used for competitive purposes or authorized by the SMUSA Finance Secretary','5']],
      'Coaching Fees' => [['Fees to trainers/coaches','6']],
      'Facilities booking/clubs membership payment to organisation' => [['Rent Fees/Membership Payment','7']],
      'Gifts' => [['Gifts/Prizes/Awards','8']],
      'Publicity' => [['General costs of marketing materials etc','9']],
      'Stationery' => [['Stationery material for club administrative purposes','10']],
      'Food and Beverages' => [['Welfare events such as BBQ, food gathering, FOR MEMBERS OF CLUB ONLY','11']],
      'Transport' => [['Fees for transportation','12']],
      'Miscellaneous' => [['Any misc. expenses that do not fall into the above cateogories','13']]
    }
    @grouped_category = {
      'Internal' => [['Within SMU only/SMU events&competitions (e.g Vivace, school held competitions)','A']],
      'External' => [['Inter-uni/with external organisations (Competitions e.g. taking part in IVP)','B'],['Inter-uni/with external organisations (Non-competitive e.g. tri-uni conferences)','C']],
      'Club-organised activties' => [['Training/Lessons/Internal club events','D'],['Events open to SMU Students only (e.g expeditions, runabout, Waikiki)','E'],['Events open to SMU Students and/or external participants (e.g IVPs, Women football clinics)','F']],
      'Administrative Operations' => [['Meetings, noticeboard decorating etc','G']]
    }
  end

  def editclaim
    @claim = Claim.find_by_id(params[:id])
    clubid = session[:club]
    control = BudgetControl.find_by_id(2)
    year = control.year
    semester = control.semester
    @events = Budget.where(clubid:clubid, year:year, semester:semester)
    @own = params[:own]
    @grouped_expense = {
      'Assets maintenance and repair' => [['Equipment with life-span of > 1 year','1']],
      'Assets purchases (Equipment with life-span of > 1 year)' => [['Assets purchases <= $100','2'],['Assets purchases $100 < X < $500','3'],['Assets purchases > $500','4']],
      'Attire' => [['Attire used for competitive purposes or authorized by the SMUSA Finance Secretary','5']],
      'Coaching Fees' => [['Fees to trainers/coaches','6']],
      'Facilities booking/clubs membership payment to organisation' => [['Rent Fees/Membership Payment','7']],
      'Gifts' => [['Gifts/Prizes/Awards','8']],
      'Publicity' => [['General costs of marketing materials etc','9']],
      'Stationery' => [['Stationery material for club administrative purposes','10']],
      'Food and Beverages' => [['Welfare events such as BBQ, food gathering, FOR MEMBERS OF CLUB ONLY','11']],
      'Transport' => [['Fees for transportation','12']],
      'Miscellaneous' => [['Any misc. expenses that do not fall into the above cateogories','13']]
    }
    @grouped_category = {
      'Internal' => [['Within SMU only/SMU events&competitions (e.g Vivace, school held competitions)','A']],
      'External' => [['Inter-uni/with external organisations (Competitions e.g. taking part in IVP)','B'],['Inter-uni/with external organisations (Non-competitive e.g. tri-uni conferences)','C']],
      'Club-organised activties' => [['Training/Lessons/Internal club events','D'],['Events open to SMU Students only (e.g expeditions, runabout, Waikiki)','E'],['Events open to SMU Students and/or external participants (e.g IVPs, Women football clinics)','F']],
      'Administrative Operations' => [['Meetings, noticeboard decorating etc','G']]
    }
  end
  
  def deleteclaim
    c = Claim.find_by_id(params[:id])
    c.delete
    redirect_to :back
  end

  def viewclaim
      @normalclaims = Claim.where(userid:session[:userid], clubid:session[:club])
  end
  def clubclaims
    role = session[:role]
    if role.include? 'clubfinsec'
      @normalclaims = Claim.where(:clubid => session[:club], :status => [1..5, 17..19])
    elsif role.include? 'cbdfinsec'
      @normalclaims = Claim.where(['clubid in (select clubid from clubs where clubtype = ?) and ((status > 2 and status < 6) or (status>16 and status<20))', session[:club]])
      @cbdmcclaims = Claim.where(clubid:session[:club], status: [7..11, 20..22])
    elsif role.include? 'president'
      @normalclaims = Claim.where(clubid:session[:club], status: [2..5, 17..19])
      @cbdmcclaims = Claim.where(clubid:session[:club], status: [8..11, 20..22]) 
      @claims = @normalclaims + @cbdmcclaims
      if session[:club] == 'smusa'
        @thirdclaims = Claim.where(['clubid in (select clubid from clubs where clubtype = ?) and ((status > 12 and status < 17) or (status > 22 and status < 26))', 'smusa'])
        @claims = @normalclaims + @cbdmcclaims + @thirdclaims
      end
      
    elsif role.include? 'smusafinsec'
      @cbdmcclaims = Claim.where(status: [9..11, 20..22])
      @smusasecclaims = Claim.where(status: [14..16, 23..25])
    elsif role.include? 'osl'
      @oslclaims = Claim.where(status: [17..25])
    end
  end

  def add
    test = false
   
    balance = ExpenditureAccount.find_by_clubid(session[:club]).Category1Balance
    amount = params[:claim][:amount]
    if current_user.nric.nil? || current_user.nric.empty?
      flash[:error] = 'There was a problem adding your claim. Have you updated your NRIC?'
    elsif amount.to_d > balance
      flash[:error] = 'There are insufficient funds in the expenditure account'
    else
      p 'Hellos!!'
      test = Claim.create(claim_params).valid?
      if !test
        flash[:error] = 'There was a problem adding your claim. Have you attached a supporting document?'
      end
    end

    
    redirect_to :action => 'viewclaim'
  end

  def claim_params
    params.require(:claim).permit!
  end

  def edit
    c = Claim.find_by_id(params[:claim][:id])
    c.update_attributes(claim_params)
    redirect_to :action => 'clubclaims'
  end
  
  def editown
    c = Claim.find_by_id(params[:claim][:id])
    c.update_attributes(claim_params)
    redirect_to :action => 'viewclaim'
  end

  def submitclaim
    c = Claim.find_by_id(params[:id])
    newstatus = c.status + 1
    ClaimTime.create(claimid: c.id, status: newstatus,date: Date.today)
    c.update_attribute(:status, newstatus)
    # redirect_to :action => 'viewclaim'
    redirect_to :back
  end
  
  def completeclaim
    c = Claim.find_by_id(params[:id])
    newstatus = c.status + 1
    ClaimTime.create(claimid: c.id, status: newstatus,date: Date.today)
    c.update_attribute(:status, newstatus)
    # redirect_to :action => 'viewclaim'
    club = c.clubid
    amount = c.amount
    account = ExpenditureAccount.find_by_clubid(club)
    balance = account.Category1Balance
    balance -= amount
    account.update_attribute(:Category1Balance, balance)
    redirect_to :back
  end

  def resubmitclaim
    c = Claim.find_by_id(params[:id])
    if c.status == 12
    newstatus = c.status + 2
    else
    newstatus = c.status + 2
    end

    c.update_attribute(:status, newstatus)
    c.update_attribute(:remarks, nil)
    
    rc = RejectedClaim.find_by_claimid(params[:id])
    if rc.status == 12
    newstatus = rc.status + 2
    else
    newstatus = rc.status + 2
    end

    rc.update_attribute(:status, newstatus)
    rc.update_attribute(:remarks, nil)
    
    # redirect_to :action => 'viewclaim'
    redirect_to :back
  end

  def confirmrejectclaim
    c = Claim.find_by_id(params[:claim][:id])

    c.update_attribute(:remarks, params[:claim][:remarks])
    c.update_attribute(:status, params[:claim][:status])
    
    # --
    
    RejectedClaim.create(claimid: c.id, clubid: c.clubid, madeby: c.userid, rejectedby: current_user.userid, amount: c.amount, status: params[:claim][:status], remarks: params[:claim][:remarks])
    
    redirect_to :action => 'clubclaims'
  end

  def viewrejectedclaim
    @rejectedclaims = RejectedClaim.all
  end

  def endorseclub
    require 'prawn'
    claim = Claim.find_by_id(params[:id])
    claim.update_attribute(:status, 4)
    ClaimTime.create(claimid: claim.id, status: 4,date: Date.today)
    claimant = User.find_by_userid(claim.userid)
    fullname = claimant.fullname
    contact = claimant.contactno
    nric = claim.nric
    eventname = claim.event
    if eventname.nil?
      eventname = '#'+claim.id.to_s+'#'
    else
      eventname = eventname+'#'+claim.id.to_s+'#'
    end
    amount = claim.amount
    category = claim.category
    expense = claim.expense
    clubfinsec = Club.find_by_clubid(claim.clubid).finsecid
    clubcode = Club.find_by_clubid(claim.clubid).clubcode
    clubpres = Club.find_by_clubid(claim.clubid).presidentid
    cbdfinsec = current_user.userid
    claimid = claim.id
    clubname = Club.find_by_clubid(claim.clubid).clubname
    cbdname = session[:club]
    date = Date.today
    Prawn::Document.generate("public/toprint.pdf") do
      # header
      bounding_box [bounds.left - 40, bounds.top + 40], :width  => bounds.width + 80 do
        cell :background_color => 'EEEEEE',
             :width => bounds.width,
             :height => 100,
             :align => :center,
             :text_color => "EEEEEE",
             :borders => [:bottom],
             :border_width => 2,
             :border_color => "rgb(1, 99, 172)",
             :padding => 12
        move_down 20
        image "#{Rails.root}/app/assets/images/smusa-new-logo.png", :at => [35, cursor], :width => 150
      end
      move_down 90
      #Body
      #Applicant Data
      data = [
                ["<b>Claim ID</b>"," : "+claimid.to_s],
                ['<b>Club Code</b>'," : "+clubcode.to_s],
                [" "," "],
                ['<b>Payee Name</b>'," : "+fullname.to_s],
                ['<b>Contact Number</b>'," : "+contact.to_s],
                ['<b>NRIC</b>'," : "+nric.to_s],
                [" "," "],
                ["<b>Date</b>"," : "+date.to_s]
              ]
      table(data, :cell_style => { :border_color => "FFFFFF", :padding => 2, :size=>10, :inline_format => true})
      move_down 20
      #Application Details
      details = [
                  ["<b>Event Name</b>","<b>Amount</b>","<b>Category</b>","<b>Expense</b>"],
                  [eventname.to_s, "$ "+amount.to_s, category.to_s, expense.to_s]
                ]
      table(details, :width => bounds.width, :cell_style => { :border_color => "rgb(1, 99, 172)", :padding => 8, :size=>10, :inline_format => true}, :row_colors => ["EEEEEE", "FFFFFF"])
      move_down 30
      #Approval Details
      approval = [
                  ["<b>Prepared and verified by</b>","<b>Certified by</b>","<b>Endorsed/Approved by</b>"],
                  [clubfinsec.to_s, clubpres.to_s,cbdfinsec.to_s],
                  [clubname.to_s+", Club Finance Secretary",clubname.to_s+", Club President", cbdname.to_s+", CBd Finance Secretary"]
                ]
      table(approval, :width => bounds.width, :cell_style => { :border_color => "FFFFFF", :padding => 10, :inline_format => true})
      move_down 50
      #Payment Approval
      paymentapprove = [
                          [{:content=>"<b>Payment Approval for Official Use</b>", :colspan=>3}],
                          ["<b>Purchase Order</b>", {:content=>" ", :colspan=>2}],
                          ["<b>SAP Vendor No.</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Cost Center</b>", {:content=>"C110 ", :colspan=>2}],
                          ["<b>Amount Code</b>","<b>Amount (S$)</b>","<b>GST (S$)</b>"],
                          ["1800020", " ", " "],
                          [" ", " ", " "],
                          [" ", " ", " "],
                          [" ", " ", " "],
                          [" ", " ", " "],
                          ["<b>Total Amount Payable</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Approval</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Document No.</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Posting Date</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Cheque No.</b>", {:content=>" ", :colspan=>2}]
                       ]
      table(paymentapprove, :cell_style => { :border_color => "rgb(1, 99, 172)", :padding => 6, :size=>10, :inline_format => true}, :row_colors => ["EEEEEE", "FFFFFF", "FFFFFF","FFFFFF", "EEEEEE", "FFFFFF", "FFFFFF","FFFFFF", "FFFFFF", "FFFFFF", "C8C8C8 ", "C8C8C8", "C8C8C8", "C8C8C8", "C8C8C8"])
      
      #Footer
      bounding_box [bounds.left-40, bounds.bottom], :width  => bounds.width+80 do
        cell :content => 'Generated Report using the SMUSA Accounting Information System',
             :background_color => 'EEEEEE',
             :width => bounds.width,
             :height => 40,
             :align => :center,
             :text_color => "#202020",
             :borders => [:top],
             :border_width => 2,
             :border_color => "rgb(1, 99, 172)",
             :padding => 12
      end
    end
    redirect_to '/toprint.pdf'
  end

  def endorsecbdmc
    require 'prawn'
    claim = Claim.find_by_id(params[:id])
    claim.update_attribute(:status, 10)
    ClaimTime.create(claimid: claim.id, status: 10,date: Date.today)
    claimant = User.find_by_userid(claim.userid)
    fullname = claimant.fullname
    contact = claimant.contactno
    nric = claim.nric
    eventname = claim.event
    if eventname.nil?
      eventname = '#'+claim.id.to_s+'#'
    else
      eventname = eventname+'#'+claim.id.to_s+'#'
    end
    amount = claim.amount
    category = claim.category
    expense = claim.expense
    cbdfinsec = Club.find_by_clubid(claim.clubid).finsecid
    clubcode = Club.find_by_clubid(claim.clubid).clubcode
    cbdpres = Club.find_by_clubid(claim.clubid).presidentid
    smusafinsec = current_user.userid
    claimid = claim.id
    clubname = Club.find_by_clubid(claim.clubid).clubname
    cbdname = session[:club]
    date = Date.today
    Prawn::Document.generate("public/toprint.pdf") do
      # header
      bounding_box [bounds.left - 40, bounds.top + 40], :width  => bounds.width + 80 do
        cell :background_color => 'EEEEEE',
             :width => bounds.width,
             :height => 100,
             :align => :center,
             :text_color => "EEEEEE",
             :borders => [:bottom],
             :border_width => 2,
             :border_color => "rgb(1, 99, 172)",
             :padding => 12
        move_down 20
        image "#{Rails.root}/app/assets/images/smusa-new-logo.png", :at => [35, cursor], :width => 150
      end
      move_down 90
      #Body
      #Applicant Data
      data = [
                ["<b>Claim ID</b>"," : "+claimid.to_s],
                ['<b>Club Code</b>'," : "+clubcode.to_s],
                [" "," "],
                ['<b>Payee Name</b>'," : "+fullname.to_s],
                ['<b>Contact Number</b>'," : "+contact.to_s],
                ['<b>NRIC</b>'," : "+nric.to_s],
                [" "," "],
                ["<b>Date</b>"," : "+date.to_s]
              ]
      table(data, :cell_style => { :border_color => "FFFFFF", :padding => 2, :size=>10, :inline_format => true})
      move_down 20
      #Application Details
      details = [
                  ["<b>Event Name</b>","<b>Amount</b>","<b>Category</b>","<b>Expense</b>"],
                  [eventname.to_s, "$ "+amount.to_s, category.to_s, expense.to_s]
                ]
      table(details, :width => bounds.width, :cell_style => { :border_color => "rgb(1, 99, 172)", :padding => 8, :size => 10,:inline_format => true}, :row_colors => ["EEEEEE", "FFFFFF"])
      move_down 30
      #Approval Details
      approval = [
                  ["<b>Prepared and verified by</b>","<b>Certified by</b>","<b>Endorsed/Approved by</b>"],
                  [cbdfinsec.to_s, cbdpres.to_s, smusafinsec.to_s],
                  [clubname.to_s+", CBd Finance Secretary",clubname.to_s+", CBd President", cbdname.to_s+", SMUSA Finance Secretary"]
                ]
      table(approval, :width => bounds.width, :cell_style => { :border_color => "FFFFFF", :padding => 6, :size=>10,  :inline_format => true})
      move_down 50
      #Payment Approval
      paymentapprove = [
                          [{:content=>"<b>Payment Approval for Official Use</b>", :colspan=>3}],
                          ["<b>Purchase Order</b>", {:content=>" ", :colspan=>2}],
                          ["<b>SAP Vendor No.</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Cost Center</b>", {:content=>"C110 ", :colspan=>2}],
                          ["<b>Amount Code</b>","<b>Amount (S$)</b>","<b>GST (S$)</b>"],
                          ["1800020", " ", " "],
                          [" ", " ", " "],
                          [" ", " ", " "],
                          [" ", " ", " "],
                          [" ", " ", " "],
                          ["<b>Total Amount Payable</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Approval</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Document No.</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Posting Date</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Cheque No.</b>", {:content=>" ", :colspan=>2}]
                       ]
      table(paymentapprove, :cell_style => { :border_color => "rgb(1, 99, 172)", :padding => 5, :size=>8, :inline_format => true}, :row_colors => ["EEEEEE", "FFFFFF", "FFFFFF","FFFFFF", "EEEEEE", "FFFFFF", "FFFFFF","FFFFFF", "FFFFFF", "FFFFFF", "C8C8C8 ", "C8C8C8", "C8C8C8", "C8C8C8", "C8C8C8"])
      
      #Footer
      bounding_box [bounds.left-40, bounds.bottom], :width  => bounds.width+80 do
        cell :content => 'Generated Report using the SMUSA Accounting Information System',
             :background_color => 'EEEEEE',
             :width => bounds.width,
             :height => 40,
             :align => :center,
             :text_color => "#202020",
             :borders => [:top],
             :border_width => 2,
             :border_color => "rgb(1, 99, 172)",
             :padding => 12
      end
    end
    redirect_to '/toprint.pdf'
  end

  def endorsesmusasec
    require 'prawn'
    claim = Claim.find_by_id(params[:id])
    claim.update_attribute(:status, 15)
    ClaimTime.create(claimid: claim.id, status: 15,date: Date.today)
    claimant = User.find_by_userid(claim.userid)
    fullname = claimant.fullname
    contact = claimant.contactno
    nric = claim.nric
    eventname = claim.event
    if eventname.nil?
      eventname = '#'+claim.id.to_s+'#'
    else
      eventname = eventname+'#'+claim.id.to_s+'#'
    end
    amount = claim.amount
    category = claim.category
    expense = claim.expense
    smusasec = claimant.userid
    smusafinsec = current_user.userid
    smusapres = Club.find_by_clubid('smusa').presidentid
    clubcode = Club.find_by_clubid(claim.clubid).clubcode
    claimid = claim.id
    clubname = Club.find_by_clubid(claim.clubid).clubname
    cbdname = session[:club]
    date = Date.today
    Prawn::Document.generate("public/toprint.pdf") do
      # header
      bounding_box [bounds.left - 40, bounds.top + 40], :width  => bounds.width + 80 do
        cell :background_color => 'EEEEEE',
             :width => bounds.width,
             :height => 100,
             :align => :center,
             :text_color => "EEEEEE",
             :borders => [:bottom],
             :border_width => 2,
             :border_color => "rgb(1, 99, 172)",
             :padding => 12
        move_down 20
        image "#{Rails.root}/app/assets/images/smusa-new-logo.png", :at => [35, cursor], :width => 150
      end
      move_down 90
      #Body
      #Applicant Data
      data = [
                ["<b>Claim ID</b>"," : "+claimid.to_s],
                ['<b>Club Code</b>'," : "+clubcode.to_s],
                ['<b>Payee Name</b>'," : "+fullname.to_s],
                ['<b>Contact Number</b>'," : "+contact.to_s],
                ['<b>NRIC</b>'," : "+nric.to_s],
                ["<b>Date</b>"," : "+date.to_s]
              ]
      table(data, :cell_style => { :border_color => "FFFFFF", :padding => 2, :size=>10, :inline_format => true})
      move_down 20
      #Application Details
      details = [
                  ["<b>Event Name</b>","<b>Amount</b>","<b>Category</b>","<b>Expense</b>"],
                  [eventname.to_s, "$ "+amount.to_s, category.to_s, expense.to_s]
                ]
      table(details, :width => bounds.width, :cell_style => { :border_color => "rgb(1, 99, 172)", :padding => 8, :size=>10, :inline_format => true}, :row_colors => ["EEEEEE", "FFFFFF"])
      move_down 30
      #Approval Details
      approval = [
                  ["<b>Prepared and verified by</b>","<b>Certified by</b>","<b>Endorsed/Approved by</b>"],
                  [smusasec.to_s, smusapres.to_s, smusafinsec.to_s],
                  [clubname.to_s+", SMUSA Honourary Secretary",cbdname.to_s+", SMUSA President", cbdname.to_s+", SMUSA Finance Secretary"]
                ]
      table(approval, :width => bounds.width, :cell_style => { :border_color => "FFFFFF", :padding => 6, :size=>10, :inline_format => true})
      move_down 50
      #Payment Approval
      paymentapprove = [
                          [{:content=>"<b>Payment Approval for Official Use</b>", :colspan=>3}],
                          ["<b>Purchase Order</b>", {:content=>" ", :colspan=>2}],
                          ["<b>SAP Vendor No.</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Cost Center</b>", {:content=>"C110 ", :colspan=>2}],
                          ["<b>Amount Code</b>","<b>Amount (S$)</b>","<b>GST (S$)</b>"],
                          ["1800020", " ", " "],
                          [" ", " ", " "],
                          [" ", " ", " "],
                          [" ", " ", " "],
                          [" ", " ", " "],
                          ["<b>Total Amount Payable</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Approval</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Document No.</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Posting Date</b>", {:content=>" ", :colspan=>2}],
                          ["<b>Cheque No.</b>", {:content=>" ", :colspan=>2}]
                       ]
      table(paymentapprove, :cell_style => { :border_color => "rgb(1, 99, 172)", :padding => 5, :size=>8, :inline_format => true}, :row_colors => ["EEEEEE", "FFFFFF", "FFFFFF","FFFFFF", "EEEEEE", "FFFFFF", "FFFFFF","FFFFFF", "FFFFFF", "FFFFFF", "C8C8C8 ", "C8C8C8", "C8C8C8", "C8C8C8", "C8C8C8"])
      
      #Footer
      bounding_box [bounds.left-40, bounds.bottom], :width  => bounds.width+80 do
        cell :content => 'Generated Report using the SMUSA Accounting Information System',
             :background_color => 'EEEEEE',
             :width => bounds.width,
             :height => 40,
             :align => :center,
             :text_color => "#202020",
             :borders => [:top],
             :border_width => 2,
             :border_color => "rgb(1, 99, 172)",
             :padding => 12
      end
    end
    redirect_to '/toprint.pdf'
  end
  
  def submitosl
    c = Claim.find_by_id(params[:id])
    status = c.status
    if status == 3
      newstatus = 17
    elsif status == 9
      newstatus = 20
    elsif status == 14
      newstatus = 23
    end

    c.update_attribute(:status, newstatus)
    # redirect_to :action => 'viewclaim'
    redirect_to :back
  end

end
