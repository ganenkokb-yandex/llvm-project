; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -mtriple=arm -passes=typepromotion,verify  -S %s -o - | FileCheck %s

define void @phi_pointers(ptr %a, ptr %b, i8 zeroext %M, i8 zeroext %N) {
; CHECK-LABEL: @phi_pointers(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[ADD:%.*]] = add nuw i8 [[M:%.*]], 1
; CHECK-NEXT:    [[AND:%.*]] = and i8 [[ADD]], 1
; CHECK-NEXT:    [[CMP:%.*]] = icmp ugt i8 [[ADD]], [[N:%.*]]
; CHECK-NEXT:    [[BASE:%.*]] = select i1 [[CMP]], ptr [[A:%.*]], ptr [[B:%.*]]
; CHECK-NEXT:    [[OTHER:%.*]] = select i1 [[CMP]], ptr [[B]], ptr [[B]]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[PTR:%.*]] = phi ptr [ [[BASE]], [[ENTRY:%.*]] ], [ [[GEP:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[IDX:%.*]] = phi i8 [ [[AND]], [[ENTRY]] ], [ [[INC:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[LOAD:%.*]] = load i16, ptr [[PTR]], align 2
; CHECK-NEXT:    [[INC]] = add nuw nsw i8 [[IDX]], 1
; CHECK-NEXT:    [[GEP]] = getelementptr inbounds i16, ptr [[PTR]], i8 [[INC]]
; CHECK-NEXT:    [[COND:%.*]] = icmp eq ptr [[GEP]], [[OTHER]]
; CHECK-NEXT:    br i1 [[COND]], label [[EXIT:%.*]], label [[LOOP]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %add = add nuw i8 %M, 1
  %and = and i8 %add, 1
  %cmp = icmp ugt i8 %add, %N
  %base = select i1 %cmp, ptr %a, ptr %b
  %other = select i1 %cmp, ptr %b, ptr %b
  br label %loop

loop:
  %ptr = phi ptr [ %base, %entry ], [ %gep, %loop ]
  %idx = phi i8 [ %and, %entry ], [ %inc, %loop ]
  %load = load i16, ptr %ptr, align 2
  %inc = add nuw nsw i8 %idx, 1
  %gep = getelementptr inbounds i16, ptr %ptr, i8 %inc
  %cond = icmp eq ptr %gep, %other
  br i1 %cond, label %exit, label %loop

exit:
  ret void
}

define void @phi_pointers_null(ptr %a, ptr %b, i8 zeroext %M, i8 zeroext %N) {
; CHECK-LABEL: @phi_pointers_null(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[ADD:%.*]] = add nuw i8 [[M:%.*]], 1
; CHECK-NEXT:    [[AND:%.*]] = and i8 [[ADD]], 1
; CHECK-NEXT:    [[CMP:%.*]] = icmp ugt i8 [[ADD]], [[N:%.*]]
; CHECK-NEXT:    [[BASE:%.*]] = select i1 [[CMP]], ptr [[A:%.*]], ptr [[B:%.*]]
; CHECK-NEXT:    [[OTHER:%.*]] = select i1 [[CMP]], ptr [[B]], ptr [[B]]
; CHECK-NEXT:    [[CMP_1:%.*]] = icmp eq ptr [[BASE]], [[OTHER]]
; CHECK-NEXT:    br i1 [[CMP_1]], label [[FAIL:%.*]], label [[LOOP:%.*]]
; CHECK:       fail:
; CHECK-NEXT:    br label [[LOOP]]
; CHECK:       loop:
; CHECK-NEXT:    [[PTR:%.*]] = phi ptr [ [[BASE]], [[ENTRY:%.*]] ], [ null, [[FAIL]] ], [ [[GEP:%.*]], [[IF_THEN:%.*]] ]
; CHECK-NEXT:    [[IDX:%.*]] = phi i8 [ [[AND]], [[ENTRY]] ], [ 0, [[FAIL]] ], [ [[INC:%.*]], [[IF_THEN]] ]
; CHECK-NEXT:    [[UNDEF:%.*]] = icmp eq ptr [[PTR]], undef
; CHECK-NEXT:    br i1 [[UNDEF]], label [[EXIT:%.*]], label [[IF_THEN]]
; CHECK:       if.then:
; CHECK-NEXT:    [[LOAD:%.*]] = load i16, ptr [[PTR]], align 2
; CHECK-NEXT:    [[INC]] = add nuw nsw i8 [[IDX]], 1
; CHECK-NEXT:    [[GEP]] = getelementptr inbounds i16, ptr [[PTR]], i8 [[INC]]
; CHECK-NEXT:    [[COND:%.*]] = icmp eq ptr [[GEP]], [[OTHER]]
; CHECK-NEXT:    br i1 [[COND]], label [[EXIT]], label [[LOOP]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %add = add nuw i8 %M, 1
  %and = and i8 %add, 1
  %cmp = icmp ugt i8 %add, %N
  %base = select i1 %cmp, ptr %a, ptr %b
  %other = select i1 %cmp, ptr %b, ptr %b
  %cmp.1 = icmp eq ptr %base, %other
  br i1 %cmp.1, label %fail, label %loop

fail:
  br label %loop

loop:
  %ptr = phi ptr [ %base, %entry ], [ null, %fail ], [ %gep, %if.then ]
  %idx = phi i8 [ %and, %entry ], [ 0, %fail ], [ %inc, %if.then ]
  %undef = icmp eq ptr %ptr, undef
  br i1 %undef, label %exit, label %if.then

if.then:
  %load = load i16, ptr %ptr, align 2
  %inc = add nuw nsw i8 %idx, 1
  %gep = getelementptr inbounds i16, ptr %ptr, i8 %inc
  %cond = icmp eq ptr %gep, %other
  br i1 %cond, label %exit, label %loop

exit:
  ret void
}

declare i8 @do_something_with_ptr(i8, ptr)

define i8 @call_pointer(i8 zeroext %x, i8 zeroext %y, ptr %a, ptr %b) {
; CHECK-LABEL: @call_pointer(
; CHECK-NEXT:    [[TMP1:%.*]] = zext i8 [[X:%.*]] to i32
; CHECK-NEXT:    [[TMP2:%.*]] = zext i8 [[Y:%.*]] to i32
; CHECK-NEXT:    [[OR:%.*]] = or i32 [[TMP1]], [[TMP2]]
; CHECK-NEXT:    [[SHR:%.*]] = lshr i32 [[OR]], 1
; CHECK-NEXT:    [[ADD:%.*]] = add nuw i32 [[SHR]], 2
; CHECK-NEXT:    [[CMP:%.*]] = icmp ne i32 [[ADD]], 0
; CHECK-NEXT:    [[PTR:%.*]] = select i1 [[CMP]], ptr [[A:%.*]], ptr [[B:%.*]]
; CHECK-NEXT:    [[TMP3:%.*]] = trunc i32 [[SHR]] to i8
; CHECK-NEXT:    [[CALL:%.*]] = tail call zeroext i8 @do_something_with_ptr(i8 [[TMP3]], ptr [[PTR]])
; CHECK-NEXT:    [[TMP4:%.*]] = zext i8 [[CALL]] to i32
; CHECK-NEXT:    [[TMP5:%.*]] = trunc i32 [[TMP4]] to i8
; CHECK-NEXT:    ret i8 [[TMP5]]
;
  %or = or i8 %x, %y
  %shr = lshr i8 %or, 1
  %add = add nuw i8 %shr, 2
  %cmp = icmp ne i8 %add, 0
  %ptr = select i1 %cmp, ptr %a, ptr %b
  %call = tail call zeroext i8 @do_something_with_ptr(i8 %shr, ptr %ptr)
  ret i8 %call
}

define i16 @pointer_to_pointer(ptr %arg, i16 zeroext %limit) {
; CHECK-LABEL: @pointer_to_pointer(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[ADDR:%.*]] = load ptr, ptr [[ARG:%.*]], align 4
; CHECK-NEXT:    [[VAL:%.*]] = load i16, ptr [[ADDR]], align 2
; CHECK-NEXT:    [[TMP0:%.*]] = zext i16 [[VAL]] to i32
; CHECK-NEXT:    [[ADD:%.*]] = add nuw i32 [[TMP0]], 7
; CHECK-NEXT:    [[CMP:%.*]] = icmp ult i32 [[ADD]], 256
; CHECK-NEXT:    [[RES:%.*]] = select i1 [[CMP]], i16 128, i16 255
; CHECK-NEXT:    ret i16 [[RES]]
;
entry:
  %addr = load ptr, ptr %arg
  %val = load i16, ptr %addr
  %add = add nuw i16 %val, 7
  %cmp = icmp ult i16 %add, 256
  %res = select i1 %cmp, i16 128, i16 255
  ret i16 %res
}

define i8 @gep_2d_array(ptr %a, i8 zeroext %arg) {
; CHECK-LABEL: @gep_2d_array(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP0:%.*]] = zext i8 [[ARG:%.*]] to i32
; CHECK-NEXT:    [[TMP1:%.*]] = load ptr, ptr [[A:%.*]], align 4
; CHECK-NEXT:    [[TMP2:%.*]] = load i8, ptr [[TMP1]], align 1
; CHECK-NEXT:    [[TMP3:%.*]] = zext i8 [[TMP2]] to i32
; CHECK-NEXT:    [[SUB:%.*]] = sub nuw i32 [[TMP3]], 1
; CHECK-NEXT:    [[CMP:%.*]] = icmp ult i32 [[SUB]], [[TMP0]]
; CHECK-NEXT:    [[RES:%.*]] = select i1 [[CMP]], i8 27, i8 54
; CHECK-NEXT:    ret i8 [[RES]]
;
entry:
  %0 = load ptr, ptr %a, align 4
  %1 = load i8, ptr %0, align 1
  %sub = sub nuw i8 %1, 1
  %cmp = icmp ult i8 %sub, %arg
  %res = select i1 %cmp, i8 27, i8 54
  ret i8 %res
}

define void @gep_2d_array_loop(ptr nocapture readonly %a, ptr nocapture readonly %b, i32 %N) {
; CHECK-LABEL: @gep_2d_array_loop(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP30:%.*]] = icmp eq i32 [[N:%.*]], 0
; CHECK-NEXT:    br i1 [[CMP30]], label [[FOR_COND_CLEANUP:%.*]], label [[FOR_COND1_PREHEADER_US:%.*]]
; CHECK:       for.cond1.preheader.us:
; CHECK-NEXT:    [[Y_031_US:%.*]] = phi i32 [ [[INC13_US:%.*]], [[FOR_COND1_FOR_COND_CLEANUP3_CRIT_EDGE_US:%.*]] ], [ 0, [[ENTRY:%.*]] ]
; CHECK-NEXT:    br label [[FOR_BODY4_US:%.*]]
; CHECK:       for.body4.us:
; CHECK-NEXT:    [[X_029_US:%.*]] = phi i32 [ 0, [[FOR_COND1_PREHEADER_US]] ], [ [[INC_US:%.*]], [[FOR_BODY4_US]] ]
; CHECK-NEXT:    [[ARRAYIDX_US:%.*]] = getelementptr inbounds ptr, ptr [[A:%.*]], i32 [[X_029_US]]
; CHECK-NEXT:    [[TMP0:%.*]] = load ptr, ptr [[ARRAYIDX_US]], align 4
; CHECK-NEXT:    [[ARRAYIDX5_US:%.*]] = getelementptr inbounds i16, ptr [[TMP0]], i32 [[Y_031_US]]
; CHECK-NEXT:    [[TMP1:%.*]] = load i16, ptr [[ARRAYIDX5_US]], align 2
; CHECK-NEXT:    [[TMP2:%.*]] = zext i16 [[TMP1]] to i32
; CHECK-NEXT:    [[DEC_US:%.*]] = add nuw i32 [[TMP2]], 65535
; CHECK-NEXT:    [[CMP6_US:%.*]] = icmp ult i32 [[DEC_US]], 16383
; CHECK-NEXT:    [[SHL_US:%.*]] = shl nuw i32 [[DEC_US]], 2
; CHECK-NEXT:    [[SPEC_SELECT_US:%.*]] = select i1 [[CMP6_US]], i32 [[SHL_US]], i32 [[DEC_US]]
; CHECK-NEXT:    [[ARRAYIDX10_US:%.*]] = getelementptr inbounds ptr, ptr [[B:%.*]], i32 [[X_029_US]]
; CHECK-NEXT:    [[TMP3:%.*]] = load ptr, ptr [[ARRAYIDX10_US]], align 4
; CHECK-NEXT:    [[ARRAYIDX11_US:%.*]] = getelementptr inbounds i16, ptr [[TMP3]], i32 [[Y_031_US]]
; CHECK-NEXT:    [[TMP4:%.*]] = trunc i32 [[SPEC_SELECT_US]] to i16
; CHECK-NEXT:    store i16 [[TMP4]], ptr [[ARRAYIDX11_US]], align 2
; CHECK-NEXT:    [[INC_US]] = add nuw i32 [[X_029_US]], 1
; CHECK-NEXT:    [[EXITCOND:%.*]] = icmp eq i32 [[INC_US]], [[N]]
; CHECK-NEXT:    br i1 [[EXITCOND]], label [[FOR_COND1_FOR_COND_CLEANUP3_CRIT_EDGE_US]], label [[FOR_BODY4_US]]
; CHECK:       for.cond1.for.cond.cleanup3_crit_edge.us:
; CHECK-NEXT:    [[INC13_US]] = add nuw i32 [[Y_031_US]], 1
; CHECK-NEXT:    [[EXITCOND32:%.*]] = icmp eq i32 [[INC13_US]], [[N]]
; CHECK-NEXT:    br i1 [[EXITCOND32]], label [[FOR_COND_CLEANUP]], label [[FOR_COND1_PREHEADER_US]]
; CHECK:       for.cond.cleanup:
; CHECK-NEXT:    ret void
;
entry:
  %cmp30 = icmp eq i32 %N, 0
  br i1 %cmp30, label %for.cond.cleanup, label %for.cond1.preheader.us

for.cond1.preheader.us:
  %y.031.us = phi i32 [ %inc13.us, %for.cond1.for.cond.cleanup3_crit_edge.us ], [ 0, %entry ]
  br label %for.body4.us

for.body4.us:
  %x.029.us = phi i32 [ 0, %for.cond1.preheader.us ], [ %inc.us, %for.body4.us ]
  %arrayidx.us = getelementptr inbounds ptr, ptr %a, i32 %x.029.us
  %0 = load ptr, ptr %arrayidx.us, align 4
  %arrayidx5.us = getelementptr inbounds i16, ptr %0, i32 %y.031.us
  %1 = load i16, ptr %arrayidx5.us, align 2
  %dec.us = add nuw i16 %1, -1
  %cmp6.us = icmp ult i16 %dec.us, 16383
  %shl.us = shl nuw i16 %dec.us, 2
  %spec.select.us = select i1 %cmp6.us, i16 %shl.us, i16 %dec.us
  %arrayidx10.us = getelementptr inbounds ptr, ptr %b, i32 %x.029.us
  %2 = load ptr, ptr %arrayidx10.us, align 4
  %arrayidx11.us = getelementptr inbounds i16, ptr %2, i32 %y.031.us
  store i16 %spec.select.us, ptr %arrayidx11.us, align 2
  %inc.us = add nuw i32 %x.029.us, 1
  %exitcond = icmp eq i32 %inc.us, %N
  br i1 %exitcond, label %for.cond1.for.cond.cleanup3_crit_edge.us, label %for.body4.us

for.cond1.for.cond.cleanup3_crit_edge.us:
  %inc13.us = add nuw i32 %y.031.us, 1
  %exitcond32 = icmp eq i32 %inc13.us, %N
  br i1 %exitcond32, label %for.cond.cleanup, label %for.cond1.preheader.us

for.cond.cleanup:
  ret void
}
